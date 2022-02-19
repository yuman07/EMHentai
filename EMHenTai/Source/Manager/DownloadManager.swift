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
    
    private let taskSet = TaskSet()
    private let groupImgNum = 40
    
    func download(book: Book) {
        Task {
            switch await downloadState(of: book) {
            case .before, .suspend:
                await taskSet.insert(book.gid)
            case .ing, .finish:
                return
            }
            
            NotificationCenter.default.post(name: DownloadManager.DownloadStateChangedNotification, object: book.gid, userInfo: nil)
            try? FileManager.default.createDirectory(at: URL(fileURLWithPath: book.folderPath), withIntermediateDirectories: true, attributes: nil)
            await p_download(of: book)
        }
    }
    
    func suspend(book: Book) {
        Task {
            await taskSet.remove(book.gid)
            NotificationCenter.default.post(name: DownloadManager.DownloadStateChangedNotification, object: book.gid, userInfo: nil)
        }
    }
    
    func remove(book: Book) {
        Task {
            await taskSet.remove(book.gid)
            try? FileManager.default.removeItem(atPath: book.folderPath)
            NotificationCenter.default.post(name: DownloadManager.DownloadStateChangedNotification, object: book.gid, userInfo: nil)
        }
    }
    
    func downloadState(of book: Book) async -> DownloadState {
        let isRunning = await taskSet.isContain(book.gid)
        if book.downloadedFileCount == book.fileCountNum {
            return .finish
        } else if isRunning {
            return .ing
        } else {
            return book.downloadedFileCount == 0 ? .before : .suspend
        }
    }
    
    private func p_download(of book: Book) async {
        await withTaskGroup(of: Void.self) { group in
            let groupNum = book.fileCountNum / groupImgNum + (book.fileCountNum % groupImgNum == 0 ? 0 : 1)
            for groupIndex in 0..<groupNum {
                guard checkGroupNeedRequest(of: book, groupIndex: groupIndex) else { continue }
                let url = book.currentWebURLString + (groupIndex > 0 ? "?p=\(groupIndex)" : "")
                group.addTask {
                    guard let value = try? await AF.request(url).serializingString().value else { return }
                    let urls = value.allIndicesOf(string: SearchInfo.currentSource.rawValue + "s/").map { index -> String in
                        let start = value.index(value.startIndex, offsetBy: index)
                        var end = value.index(after: start)
                        while value[end] != "\"" && end < value.endIndex {
                            end = value.index(after: end)
                        }
                        return "\(value[start..<end])"
                    }
                    guard !urls.isEmpty else { return }
                    guard await self.downloadState(of: book) == .ing else { return }
                    
                    await withTaskGroup(of: Void.self) { imgGroup in
                        for (urlIndex, url) in urls.enumerated() {
                            let realIndex = groupIndex * self.groupImgNum + urlIndex
                            guard !FileManager.default.fileExists(atPath: book.imagePath(at: realIndex)) else { continue }
                            
                            imgGroup.addTask {
                                guard let value = try? await AF.request(url).serializingString().value else { return }
                                guard let showKey = value.range(of: "showkey=\"").map({ range -> Substring in
                                    let start = range.upperBound
                                    var end = value.index(after: start)
                                    while value[end] != "\"" && end < value.endIndex {
                                        end = value.index(after: end)
                                    }
                                    return value[start..<end]
                                }) else { return }
                                guard await self.downloadState(of: book) == .ing else { return }
                                
                                guard let model = try? await AF.request(
                                    SearchInfo.currentSource.rawValue + "api.php",
                                    method: .post,
                                    parameters: [
                                        "method": "showpage",
                                        "gid": book.gid,
                                        "page": realIndex + 1,
                                        "imgkey": url.split(separator: "/").reversed()[1],
                                        "showkey": showKey],
                                    encoding: JSONEncoding.default
                                ).serializingDecodable(GroupModel.self).value else { return }
                                guard await self.downloadState(of: book) == .ing else { return }
                                
                                guard let imgURL = model.i3.range(of: "src=\"").map({ range -> String in
                                    let start = range.upperBound
                                    var end = model.i3.index(after: start)
                                    while model.i3[end] != "\"" && end < model.i3.endIndex {
                                        end = model.i3.index(after: end)
                                    }
                                    return "\(model.i3[start..<end])"
                                }) else { return }
                                
                                guard let u = try? await AF
                                        .download(imgURL, to: { _, _ in (URL(fileURLWithPath: book.imagePath(at: realIndex)), []) })
                                        .serializingDownloadedFileURL()
                                        .value else { return }
                                
                                guard FileManager.default.fileExists(atPath: u.path) else { return }
                                NotificationCenter.default.post(name: DownloadManager.DownloadPageSuccessNotification, object: (book.gid, realIndex), userInfo: nil)
                                if book.downloadedFileCount == book.fileCountNum {
                                    await self.taskSet.remove(book.gid)
                                    NotificationCenter.default.post(name: DownloadManager.DownloadStateChangedNotification, object: book.gid, userInfo: nil)
                                }
                            }
                        }
                    }
                }
            }
        }
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

private actor TaskSet {
    var runningDownload = Set<Int>()
    
    func insert(_ gid: Int) {
        runningDownload.insert(gid)
    }
    
    func remove(_ gid: Int) {
        runningDownload.remove(gid)
    }
    
    func isContain(_ gid: Int) -> Bool {
        runningDownload.contains(gid)
    }
}

private struct GroupModel: Codable {
    let i3: String
}
