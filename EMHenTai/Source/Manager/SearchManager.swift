//
//  SearchManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import Alamofire

class SearchManager {
    static let shared = SearchManager()
    private init() {}
    
    private let lock = NSLock()
    private var runningURL: String?
    private var waitingRequest: (info: SearchInfo, completion: ([Book]) -> Void)?
    
    func searchWith(info: SearchInfo, completion: @escaping ([Book]) -> Void) {
        let url = info.requestString
        
        do {
            lock.lock()
            defer { lock.unlock() }
            if runningURL == nil {
                runningURL = url
            } else if runningURL! == url {
                return
            } else {
                waitingRequest = (info, completion)
                return
            }
        }
        
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
                    self.requestFinish(result: [], completion: completion)
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
                        self.requestFinish(result: value.gmetadata, completion: completion)
                    case .failure:
                        self.requestFinish(result: [], completion: completion)
                    }
                }
            case .failure:
                self.requestFinish(result: [], completion: completion)
            }
        }
    }
    
    private func requestFinish(result: [Book], completion: @escaping ([Book]) -> Void) {
        lock.lock()
        if waitingRequest == nil {
            lock.unlock()
            DispatchQueue.main.async {
                completion(result)
            }
        } else {
            let next = waitingRequest!
            runningURL = nil
            waitingRequest = nil
            lock.unlock()
            searchWith(info: next.info, completion: next.completion)
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
