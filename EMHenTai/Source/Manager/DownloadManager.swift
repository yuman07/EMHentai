//
//  DownloadManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import Alamofire
import SwiftUI

enum DownloadState {
    case before
    case ing
    case suspend
    case finish
}

class DownloadManager {
    static let shared = DownloadManager()
    private init() {}
    private static let maxConcurrentOperationCount = 6
    static let DownloadPageSuccessNotification = NSNotification.Name(rawValue: "EMHenTai.DownloadManager.DownloadPageSuccessNotification")
    
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
        
        getImageString(of: book) { index, imgString in
            if self.downloadState(of: book) != .ing { return }
            
            let destination: DownloadRequest.Destination = { _, _ in
                (URL(fileURLWithPath: FilePathHelper.imagePath(of: book, at: index)), [.removePreviousFile, .createIntermediateDirectories])
            }
            AF.download(imgString, to: destination).response { response in
                switch response.result {
                case .success:
                    NotificationCenter.default.post(name: DownloadManager.DownloadPageSuccessNotification,
                                                    object: book.gid,
                                                    userInfo: nil)
                case .failure:
                    break
                }
            }
        }
    }
    
    func suspend(book: Book) {
        lock.lock()
        runningDownload.remove(book.gid)
        lock.unlock()
    }
    
    func downloadState(of book: Book) -> DownloadState {
        lock.lock()
        let isRunning = runningDownload.contains(book.gid)
        lock.unlock()
        
        let contents = try? FileManager.default.contentsOfDirectory(atPath: FilePathHelper.bookFolderPath(of: book))
        
        if contents == nil || contents!.isEmpty {
            return isRunning ? .ing : .before
        } else if "\(contents!.count)" == book.filecount {
            return .finish
        } else {
            return isRunning ? .ing : .suspend
        }
    }
    
    private func getImageString(of book: Book, completion: @escaping (Int, String) -> Void) {
        let url = "\(SearchInfo().source)g/\(book.gid)/\(book.token)/?inline_set=ts_m"
        AF.request(url).responseString(queue: .global()) { response in
            switch response.result {
            case .success(let value):
                if self.downloadState(of: book) != .ing { return }
                
                let urls = value.allIndicesOf(string: SearchInfo().source + "s/").map { index -> String in
                    let start = value.index(value.startIndex, offsetBy: index)
                    var end = value.index(after: start)
                    while value[end] != "\"" {
                        end = value.index(after: end)
                    }
                    return "\(value[start..<end])"
                }
                
                for (index, pageURL) in urls.enumerated() {
                    AF.request(pageURL).responseString(queue: .global()) { response in
                        switch response.result {
                        case .success(let value):
                            if self.downloadState(of: book) != .ing { return }
                            
                            guard let showKey = value.range(of: "showkey=\"").map({ range -> Substring in
                                let start = range.upperBound
                                var end = value.index(after: start)
                                while value[end] != "\"" {
                                    end = value.index(after: end)
                                }
                                return value[start..<end]
                            }) else { return }
                            
                            AF.request(
                                SearchInfo().source + "api.php",
                                method: .post,
                                parameters: [
                                    "method": "showpage",
                                    "gid": book.gid,
                                    "page": (index + 1),
                                    "imgkey": pageURL.split(separator: "/").reversed()[1],
                                    "showkey": showKey,
                                ],
                                encoding: JSONEncoding.default
                            ).responseDecodable(of: ImagePageResult.self, queue: .global()) { response in
                                switch response.result {
                                case .success(let value):
                                    if self.downloadState(of: book) != .ing { return }
                                    
                                    guard let img = value.i3.range(of: "src=\"").map({ range -> String in
                                        let start = range.upperBound
                                        var end = value.i3.index(after: start)
                                        while value.i3[end] != "\"" {
                                            end = value.i3.index(after: end)
                                        }
                                        return "\(value.i3[start..<end])"
                                    }) else { return }
                                    
                                    completion(index, img)
                                case .failure:
                                    break
                                }
                            }
                            
                        case .failure:
                            break
                        }
                    }
                }
            case .failure:
                break
            }
        }
    }
}

private struct ImagePageResult: Codable {
    let i3: String
}
