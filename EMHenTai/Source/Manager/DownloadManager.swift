//
//  DownloadManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Alamofire
import Combine
import Foundation
import Kingfisher

final actor DownloadManager {
    // 整个本子的下载状态
    enum State {
        case before
        case ing
        case suspend
        case finish
    }
    
    static let shared = DownloadManager()
    
    nonisolated let downloadStateChangedSubject = PassthroughSubject<(book: Book, state: State), Never>()
    nonisolated let downloadPageProgressSubject = PassthroughSubject<(book: Book, index: Int, progress: Progress), Never>()
    nonisolated let downloadPageSuccessSubject = PassthroughSubject<(book: Book, index: Int), Never>()
    
    private init() {}
    private let groupTotalImgNum = 40
    private var taskMap = [Int: Task<Void, Never>]()
    
    nonisolated func download(_ book: Book) {
        Task { await checkAndDownload(book) }
    }
    
    private func checkAndDownload(_ book: Book) {
        guard case let state = downloadState(of: book), state != .ing && state != .finish else { return }
        
        try? FileManager.default.createDirectory(at: URL(fileURLWithPath: book.folderPath), withIntermediateDirectories: true)
        
        taskMap[book.gid] = Task {
            await startDownload(book)
            taskMap[book.gid] = nil
            downloadStateChangedSubject.send((book, downloadState(of: book)))
        }
        
        downloadStateChangedSubject.send((book, .ing))
    }
    
    nonisolated func suspend(_ book: Book) {
        Task { await privateSuspend(book) }
    }
    
    nonisolated func remove(_ book: Book) {
        Task { await privateRemove(book) }
    }
    
    private func privateSuspend(_ book: Book) {
        taskMap[book.gid]?.cancel()
        taskMap[book.gid] = nil
        downloadStateChangedSubject.send((book, .suspend))
    }
    
    private func privateRemove(_ book: Book) {
        taskMap[book.gid]?.cancel()
        taskMap[book.gid] = nil
        try? FileManager.default.removeItem(atPath: book.folderPath)
        downloadStateChangedSubject.send((book, .before))
    }
    
    func downloadState(of book: Book) -> State {
        if book.downloadedImgCount == book.contentImgCount + 1 {
            return .finish
        } else if taskMap[book.gid] != nil {
            return .ing
        } else {
            return book.downloadedImgCount == 0 ? .before : .suspend
        }
    }
    
    private nonisolated func startDownload(_ book: Book) async {
        if !FileManager.default.fileExists(atPath: book.coverImagePath) {
            let from = KingfisherManager.shared.cache.diskStorage.cacheFileURL(forKey: book.thumb)
            if FileManager.default.fileExists(atPath: from.path) {
                let to = URL(fileURLWithPath: book.coverImagePath)
                try? FileManager.default.copyItem(at: from, to: to)
            } else {
                _ = try? await emSession
                    .download(book.thumb, interceptor: RetryPolicy.downloadRetryPolicy, to: { _, _ in (URL(fileURLWithPath: book.coverImagePath), []) })
                    .serializingDownload(using: URLResponseSerializer())
                    .value
            }
        }
        
        guard !Task.isCancelled else { return }
        
        let urlStream = AsyncStream<String> { continuation in
            Task {
                await withTaskGroup(of: Void.self, body: { group in
                    let groupNum = book.contentImgCount / groupTotalImgNum + (book.contentImgCount % groupTotalImgNum == 0 ? 0 : 1)
                    for groupIndex in 0 ..< groupNum {
                        guard checkGroupNeedRequest(of: book, groupIndex: groupIndex) else { continue }
                        group.addTask {
                            let url = book.currentWebURLString + (groupIndex > 0 ? "?p=\(groupIndex)" : "") + "/?nw=session"
                            guard let value = try? await emSession.request(url, interceptor: RetryPolicy.downloadRetryPolicy).serializingString().value else { return }
                            guard !Task.isCancelled else { return }
                            let baseURL = SearchInfo.currentSource.rawValue + "s/"
                            value.allSubString(of: baseURL, endCharater: "\"").forEach { continuation.yield(baseURL + $0) }
                        }
                        await group.waitForAll()
                        guard !Task.isCancelled else { return }
                    }
                })
                continuation.finish()
            }
        }
        
        await withTaskGroup(of: Void.self, body: { group in
            for await url in urlStream {
                guard !Task.isCancelled else { return }
                let imgIndex = (url.split(separator: "-").last.flatMap({ Int($0) }) ?? 1) - 1
                guard !FileManager.default.fileExists(atPath: book.imagePath(at: imgIndex)) else { continue }
                
                group.addTask {
                    guard let html = try? await emSession.request(url, interceptor: RetryPolicy.downloadRetryPolicy).serializingString().value else { return }
                    guard !Task.isCancelled else { return }
                    guard let imgURL = html.allSubString(of: "<img id=\"img\" src=\"", endCharater: "\"").first else { return }
                    
                    guard let p = try? await emSession
                        .download(imgURL, interceptor: RetryPolicy.downloadRetryPolicy, to: { _, _ in (URL(fileURLWithPath: book.imagePath(at: imgIndex)), []) })
                        .downloadProgress(queue: .main, closure: { [weak self] progress in
                            guard let self else { return }
                            downloadPageProgressSubject.send((book, imgIndex, progress))
                        })
                            .serializingDownload(using: URLResponseSerializer())
                            .value,
                            FileManager.default.fileExists(atPath: p.path)
                    else { return }
                    
                    Task { @DownloadManagerActor in
                        self.downloadPageSuccessSubject.send((book, imgIndex))
                    }
                }
            }
        })
    }
    
    private nonisolated func checkGroupNeedRequest(of book: Book, groupIndex: Int) -> Bool {
        for index in 0 ..< groupTotalImgNum {
            guard case let realIndex = groupIndex * groupTotalImgNum + index, realIndex < book.contentImgCount else {
                break
            }
            if !FileManager.default.fileExists(atPath: book.imagePath(at: realIndex)) {
                return true
            }
        }
        return false
    }
}

private extension RetryPolicy {
    static let downloadRetryPolicy = RetryPolicy(retryLimit: 6)
}

@globalActor private actor DownloadManagerActor {
    static let shared = DownloadManagerActor()
}

