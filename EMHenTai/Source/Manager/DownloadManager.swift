//
//  DownloadManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import Alamofire

class DownloadManager {
    static let shared = DownloadManager()
    private init() {}
    private static let maxConcurrentOperationCount = 6
    
    func download(book: Book) {
        getImageString(of: book) { index, imgString in
            print("\(index) : \(imgString)")
        }
    }
    
    private func getImageString(of book: Book, completion: @escaping (Int, String) -> Void) {
        let url = "\(SearchInfo().source)g/\(book.gid)/\(book.token)/?inline_set=ts_m"
        AF.request(url).responseString(queue: .global()) { response in
            switch response.result {
            case .success(let value):
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
                            let showKey = value.range(of: "showkey=\"").map { range -> Substring in
                                let start = range.upperBound
                                var end = value.index(after: start)
                                while value[end] != "\"" {
                                    end = value.index(after: end)
                                }
                                return value[start..<end]
                            }
                            guard let showKey = showKey else { return }
                            
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
                                    let res = value.i3.range(of: "src=\"").map { range -> String in
                                        let start = range.upperBound
                                        var end = value.i3.index(after: start)
                                        while value.i3[end] != "\"" {
                                            end = value.i3.index(after: end)
                                        }
                                        return "\(value.i3[start..<end])"
                                    }
                                    if let res = res {
                                        completion(index, res)
                                    }
                                case .failure:
                                    print("error")
                                }
                            }
                            
                        case .failure:
                            print("error")
                        }
                    }
                }
            case .failure:
                print("error")
            }
        }
    }
}

private struct ImagePageResult: Codable {
    let i3: String
}
