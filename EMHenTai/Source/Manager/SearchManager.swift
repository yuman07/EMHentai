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
    
    private let lock = NSLock()
    private var runningURL: String?
    private var waitingRequest: (info: SearchInfo, completion: (([Book], String) -> Void))?
    
    func searchWith(info: SearchInfo, completion: @escaping ([Book], String) -> Void) -> String {
        let url = info.requestString
        lock.lock()
        defer { lock.unlock() }
        
        if runningURL == nil {
            runningURL = url
            p_searchWith(info: info, completion: completion)
        } else if runningURL! == url {
            // skip same request
        } else {
            waitingRequest = (info, completion)
        }
        return url
    }
    
    private func p_searchWith(info: SearchInfo, completion: @escaping ([Book], String) -> Void) {
        let url = info.requestString
        AF.request(url).responseString(queue: .global()) { response in
            switch response.result {
            case .success(let value):
                let target = info.source + "g/"
                let ids = value.allIndicesOf(string: target).map { index -> [Substring] in
                    var count = 0
                    let start = value.index(value.startIndex, offsetBy: index + target.count)
                    var end = value.index(after: start)
                    while count < 2 {
                        if value[end] == "/" { count += 1 }
                        end = value.index(after: end)
                    }
                    return value[start..<end].split(separator: "/")
                }
                
                if ids.count == 0 {
                    self.requestFinish(result: ([], url), completion: completion)
                    return
                }
                
                AF.request(
                    info.source + "api.php",
                    method: .post,
                    parameters: [
                        "method": "gdata",
                        "gidlist": ids
                    ],
                    encoding: JSONEncoding.default
                ).responseDecodable(of: Gmetadata.self, queue: .global()) { response in
                    switch response.result {
                    case .success(let value):
                        self.requestFinish(result: (value.gmetadata, url), completion: completion)
                    case .failure:
                        self.requestFinish(result: ([], url), completion: completion)
                    }
                }
            case .failure:
                self.requestFinish(result: ([], url), completion: completion)
            }
        }
    }
    
    private func requestFinish(result: ([Book], String), completion: @escaping ([Book], String) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        
        runningURL = nil
        if let next = waitingRequest {
            runningURL = next.info.requestString
            waitingRequest = nil
            p_searchWith(info: next.info, completion: completion)
        }
        
        DispatchQueue.main.async {
            completion(result.0, result.1)
        }
    }
}

fileprivate extension String {
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
