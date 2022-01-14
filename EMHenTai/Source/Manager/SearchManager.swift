//
//  SearchManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import Alamofire
import CommonCrypto

class SearchManager {
    static let shared = SearchManager()
    private init() {}
    
    let lock = NSLock()
    var runningRequest: Set<String> = []
    
    func searchWith(info: SearchInfo, pageIndex: Int, completion: @escaping ([Book], String) -> Void) -> String {
        let url = info.requestStringAt(pageIndex)
        let requestID = url.SHA256
        lock.lock()
        if runningRequest.contains(requestID) {
            lock.unlock()
            return requestID
        }
        runningRequest.insert(requestID)
        lock.unlock()
        
        AF.request(url).responseString(queue: .global()) { response in
            switch response.result {
            case .success(let value):
                let target = info.source.rawValue + "g/"
                let ids = value.allIndicesOf(string: target).map { index -> [String] in
                    var count = 0
                    let start = value.index(value.startIndex, offsetBy: index + target.count)
                    var end = start
                    while count < 2 {
                        if value[end] == "/" {
                            count += 1
                        }
                        end = value.index(after: end)
                    }
                    return value[start..<end].split(separator: "/").map { "\($0)" }
                }
                
                if ids.count == 0 {
                    self.requestFinish(result: ([], requestID), completion: completion)
                    return
                }
                
                AF.request(
                    info.source.rawValue + "api.php",
                    method: .post,
                    parameters: [
                        "method": "gdata",
                        "gidlist": ids
                    ],
                    encoding: JSONEncoding.default
                ).responseJSON(queue: .global()) { response in
                    switch response.result {
                    case .success(let value):
                        guard let value = value as? [String: Any], let content = value["gmetadata"] as? [Any] else {
                            self.requestFinish(result: ([], requestID), completion: completion)
                            return
                        }
                        
                        var result = [Book]()
                        for obj in content {
                            if let data = try? JSONSerialization.data(withJSONObject: obj, options: []),
                               let book = try? JSONDecoder().decode(Book.self, from: data) {
                                result.append(book)
                            }
                        }
                        self.requestFinish(result: (result, requestID), completion: completion)
                    case .failure:
                        self.requestFinish(result: ([], requestID), completion: completion)
                    }
                }
            case .failure:
                self.requestFinish(result: ([], requestID), completion: completion)
            }
        }
        return requestID
    }
    
    private func requestFinish(result: ([Book], String), completion: @escaping ([Book], String) -> Void) {
        lock.lock()
        runningRequest.remove(result.1)
        lock.unlock()
        DispatchQueue.main.async {
            completion(result.0, result.1)
        }
    }
}

fileprivate extension String {
    var SHA256: String {
        let utf8 = cString(using: .utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(utf8, CC_LONG(utf8!.count - 1), &digest)
        return digest.reduce("") { $0 + String(format:"%02x", $1) }
    }
    
    func allIndicesOf(string: String) -> [Int] {
        var indices = [Int]()
        var searchStartIndex = self.startIndex
        while searchStartIndex < self.endIndex, let range = self.range(of: string, range: searchStartIndex..<self.endIndex), !range.isEmpty {
            let index = distance(from: self.startIndex, to: range.lowerBound)
            indices.append(index)
            searchStartIndex = range.upperBound
        }
        return indices
    }
}
