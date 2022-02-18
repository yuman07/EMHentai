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
    private static let maxConcurrentOperationCount = 6
    static let DownloadPageSuccessNotification = NSNotification.Name(rawValue: "EMHenTai.DownloadManager.DownloadPageSuccessNotification")
    static let DownloadStateChangedNotification = NSNotification.Name(rawValue: "EMHenTai.DownloadManager.DownloadStateChangedNotification")
    
    private let lock = NSLock()
    private var runningDownload = Set<Int>()
    
    func download(book: Book) {
        switch downloadState(of: book) {
        case .before, .suspend:
            lock.lock()
            runningDownload.insert(book.gid)
            lock.unlock()
        case .ing, .finish:
            return
        }
        
        NotificationCenter.default.post(name: DownloadManager.DownloadStateChangedNotification, object: book.gid, userInfo: nil)
        try? FileManager.default.createDirectory(at: URL(fileURLWithPath: book.folderPath), withIntermediateDirectories: true, attributes: nil)
        downloadGroup(book: book, groupIndex: 0, finishImgCount: 0)
    }
    
    func suspend(book: Book) {
        lock.lock()
        runningDownload.remove(book.gid)
        lock.unlock()
        NotificationCenter.default.post(name: DownloadManager.DownloadStateChangedNotification, object: book.gid, userInfo: nil)
    }
    
    func remove(book: Book) {
        lock.lock()
        runningDownload.remove(book.gid)
        lock.unlock()
        try? FileManager.default.removeItem(atPath: book.folderPath)
        NotificationCenter.default.post(name: DownloadManager.DownloadStateChangedNotification, object: book.gid, userInfo: nil)
    }
    
    func downloadState(of book: Book) -> DownloadState {
        lock.lock()
        let isRunning = runningDownload.contains(book.gid)
        lock.unlock()
        
        if book.downloadedFileCount == book.fileCountNum {
            return .finish
        } else if isRunning {
            return .ing
        } else {
            return book.downloadedFileCount == 0 ? .before : .suspend
        }
    }
    
    private func downloadGroup(book: Book, groupIndex: Int, finishImgCount: Int) {
        if self.downloadState(of: book) != .ing { return }
        
        var curImgCount = 0
        let curImgLock = NSLock()
        self.getImageString(of: book, groupIndex: groupIndex, finishImgCount: finishImgCount) { groupImgCount, index, imgString in
            if self.downloadState(of: book) != .ing { return }
            
            AF.download(imgString, to: { _, _ in
                (URL(fileURLWithPath: book.imagePath(at: index)), [])
            }).response { _ in
                if FileManager.default.fileExists(atPath: book.imagePath(at: index)) {
                    if book.downloadedFileCount == book.fileCountNum {
                        self.lock.lock()
                        self.runningDownload.remove(book.gid)
                        self.lock.unlock()
                        NotificationCenter.default.post(name: DownloadManager.DownloadStateChangedNotification, object: book.gid, userInfo: nil)
                    }
                    NotificationCenter.default.post(name: DownloadManager.DownloadPageSuccessNotification, object: (book.gid, index), userInfo: nil)
                }
                
                curImgLock.lock()
                defer { curImgLock.unlock() }
                curImgCount += 1
                if curImgCount == groupImgCount && finishImgCount + curImgCount < book.fileCountNum {
                    self.downloadGroup(book: book, groupIndex: groupIndex + 1, finishImgCount: finishImgCount + curImgCount)
                }
            }
        }
    }
    
    private func getImageString(of book: Book, groupIndex: Int, finishImgCount: Int, completion: @escaping (Int, Int, String) -> Void) {
        var url = book.currentWebURLString
        if groupIndex > 0 { url += "?p=\(groupIndex)" }
        
        AF.request(url).responseString(queue: .global()) { response in
            if self.downloadState(of: book) != .ing { return }
            
            var value = ""
            switch response.result {
            case .success(let html):
                value = html
            case .failure:
                value = response.data.flatMap { String(data: $0, encoding: .isoLatin1) } ?? ""
            }
            
            guard !value.isEmpty else { return }
            
            let urls = value.allIndicesOf(string: SearchInfo.currentSource.rawValue + "s/").map { index -> String in
                let start = value.index(value.startIndex, offsetBy: index)
                var end = value.index(after: start)
                while value[end] != "\"" && end < value.endIndex {
                    end = value.index(after: end)
                }
                return "\(value[start..<end])"
            }.enumerated().map { (index, url) in
                (index, FileManager.default.fileExists(atPath: book.imagePath(at: index + finishImgCount)) ? "" : url)
            }
            let groupNum = urls.count
            
            let sema = DispatchSemaphore(value: DownloadManager.maxConcurrentOperationCount)
            for (index, pageURL) in urls {
                sema.wait()
                if self.downloadState(of: book) != .ing { sema.signal(); return }
                
                AF.request(pageURL).responseString(queue: .global()) { response in
                    if self.downloadState(of: book) != .ing { sema.signal(); return }
                    
                    switch response.result {
                    case .success(let value):
                        guard let showKey = value.range(of: "showkey=\"").map({ range -> Substring in
                            let start = range.upperBound
                            var end = value.index(after: start)
                            while value[end] != "\"" && end < value.endIndex {
                                end = value.index(after: end)
                            }
                            return value[start..<end]
                        }) else { sema.signal(); completion(groupNum, index + finishImgCount, ""); return }
                        
                        AF.request(
                            SearchInfo.currentSource.rawValue + "api.php",
                            method: .post,
                            parameters: [
                                "method": "showpage",
                                "gid": book.gid,
                                "page": (index + finishImgCount + 1),
                                "imgkey": pageURL.split(separator: "/").reversed()[1],
                                "showkey": showKey,
                            ],
                            encoding: JSONEncoding.default
                        ).responseDecodable(of: GroupModel.self, queue: .global()) { response in
                            if self.downloadState(of: book) != .ing { sema.signal(); return }
                            
                            switch response.result {
                            case .success(let value):
                                guard let img = value.i3.range(of: "src=\"").map({ range -> String in
                                    let start = range.upperBound
                                    var end = value.i3.index(after: start)
                                    while value.i3[end] != "\"" && end < value.i3.endIndex {
                                        end = value.i3.index(after: end)
                                    }
                                    return "\(value.i3[start..<end])"
                                }) else { sema.signal(); completion(groupNum, index + finishImgCount, ""); return }
                                
                                sema.signal()
                                completion(groupNum, index + finishImgCount, img)
                            case .failure:
                                sema.signal()
                                completion(groupNum, index + finishImgCount, "")
                            }
                        }
                    case .failure:
                        sema.signal()
                        completion(groupNum, index + finishImgCount, "")
                    }
                }
            }
        }
    }
}

private struct GroupModel: Codable {
    let i3: String
}
