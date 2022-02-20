//
//  DownloadManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import Alamofire

class DownloadManager {
    enum DownloadState {
        case before
        case ing
        case suspend
        case finish
    }
    
    static let shared = DownloadManager()
    private init() {}
    static let DownloadPageSuccessNotification = NSNotification.Name(rawValue: "EMHenTai.DownloadManager.DownloadPageSuccessNotification")
    static let DownloadStateChangedNotification = NSNotification.Name(rawValue: "EMHenTai.DownloadManager.DownloadStateChangedNotification")
    
    private let taskMap = TaskMap()
    private let groupImgNum = 40
    private let maxConcurrentDowloadCount = 10
    
    func download(book: Book) {
        Task {
            let state = await downloadState(of: book)
            if state == .ing || state == .finish {
                return
            }
            
            try? FileManager.default.createDirectory(at: URL(fileURLWithPath: book.folderPath), withIntermediateDirectories: true, attributes: nil)
            await taskMap.set(Task { await p_download(of: book) }, for: book.gid)
            NotificationCenter.default.post(name: DownloadManager.DownloadStateChangedNotification, object: book.gid, userInfo: nil)
        }
    }
    
    func suspend(book: Book) {
        Task {
            await taskMap.remove(book.gid)
            NotificationCenter.default.post(name: DownloadManager.DownloadStateChangedNotification, object: book.gid, userInfo: nil)
        }
    }
    
    func remove(book: Book) {
        Task {
            await taskMap.remove(book.gid)
            try? FileManager.default.removeItem(atPath: book.folderPath)
            NotificationCenter.default.post(name: DownloadManager.DownloadStateChangedNotification, object: book.gid, userInfo: nil)
        }
    }
    
    func downloadState(of book: Book) async -> DownloadState {
        let isRunning = await taskMap.isContain(book.gid)
        if book.downloadedFileCount == book.fileCountNum {
            return .finish
        } else if isRunning {
            return .ing
        } else {
            return book.downloadedFileCount == 0 ? .before : .suspend
        }
    }
    
    private func p_download(of book: Book) async {
        var urlStream: AsyncStream<String> {
            AsyncStream<String> { continuation in
                Task {
                    await withTaskGroup(of: Void.self, body: { group in
                        let groupNum = book.fileCountNum / groupImgNum + (book.fileCountNum % groupImgNum == 0 ? 0 : 1)
                        for groupIndex in 0..<groupNum {
                            guard checkGroupNeedRequest(of: book, groupIndex: groupIndex) else { continue }
                            await group.waitForAll()
                            group.addTask {
                                let url = book.currentWebURLString + (groupIndex > 0 ? "?p=\(groupIndex)" : "")
                                guard let value = try? await AF.request(url).serializingString(automaticallyCancelling: true).value else { return }
                                let urls = value.allIndicesOf(string: SearchInfo.currentSource.rawValue + "s/").map { index -> String in
                                    let start = value.index(value.startIndex, offsetBy: index)
                                    var end = value.index(after: start)
                                    while value[end] != "\"" && end < value.endIndex {
                                        end = value.index(after: end)
                                    }
                                    return "\(value[start..<end])"
                                }
                                urls.forEach { continuation.yield($0) }
                            }
                        }
                    })
                    continuation.finish()
                }
            }
        }
        
        await withTaskGroup(of: Void.self, body: { group in
            var count = 0
            for await url in urlStream {
                let imgIndex = (url.split(separator: "-").last.flatMap({ Int("\($0)") }) ?? 1) - 1
                guard !FileManager.default.fileExists(atPath: book.imagePath(at: imgIndex)) else { continue }
                
                count += 1
                if count > maxConcurrentDowloadCount {
                    await group.next()
                }
                
                group.addTask {
                    guard let value = try? await AF.request(url).serializingString(automaticallyCancelling: true).value else { return }
                    guard let showKey = value.range(of: "showkey=\"").map({ range -> Substring in
                        let start = range.upperBound
                        var end = value.index(after: start)
                        while value[end] != "\"" && end < value.endIndex {
                            end = value.index(after: end)
                        }
                        return value[start..<end]
                    }) else { return }
                    
                    guard let model = try? await AF.request(
                        SearchInfo.currentSource.rawValue + "api.php",
                        method: .post,
                        parameters: [
                            "method": "showpage",
                            "gid": book.gid,
                            "page": imgIndex + 1,
                            "imgkey": url.split(separator: "/").reversed()[1],
                            "showkey": showKey],
                        encoding: JSONEncoding.default
                    ).serializingDecodable(GroupModel.self, automaticallyCancelling: true).value else { return }
                    
                    guard let imgURL = model.i3.range(of: "src=\"").map({ range -> String in
                        let start = range.upperBound
                        var end = model.i3.index(after: start)
                        while model.i3[end] != "\"" && end < model.i3.endIndex {
                            end = model.i3.index(after: end)
                        }
                        return "\(model.i3[start..<end])"
                    }) else { return }
                    
                    guard let u = try? await AF
                            .download(imgURL, to: { _, _ in (URL(fileURLWithPath: book.imagePath(at: imgIndex)), []) })
                            .serializingDownload(using: URLResponseSerializer(), automaticallyCancelling: true)
                            .value else { return }
                    
                    guard FileManager.default.fileExists(atPath: u.path) else { return }
                    NotificationCenter.default.post(name: DownloadManager.DownloadPageSuccessNotification, object: (book.gid, imgIndex), userInfo: nil)
                    if book.downloadedFileCount == book.fileCountNum {
                        await self.taskMap.remove(book.gid)
                        NotificationCenter.default.post(name: DownloadManager.DownloadStateChangedNotification, object: book.gid, userInfo: nil)
                    }
                }
            }
        })
    }
    
    private func checkGroupNeedRequest(of book: Book, groupIndex: Int) -> Bool {
        for index in 0..<groupImgNum {
            let realIndex = groupIndex * groupImgNum + index
            if realIndex >= book.fileCountNum { break }
            if !FileManager.default.fileExists(atPath: book.imagePath(at: realIndex)) {
                return true
            }
        }
        return false
    }
}

private actor TaskMap {
    var map = [Int: Task<Void, Never>]()
    
    func set(_ task: Task<Void, Never>, for gid: Int) {
        map[gid] = task
    }
    
    func remove(_ gid: Int) {
        let task = map.removeValue(forKey: gid)
        task?.cancel()
    }
    
    func isContain(_ gid: Int) -> Bool {
        map[gid] != nil
    }
}

private struct GroupModel: Codable {
    let i3: String
}
