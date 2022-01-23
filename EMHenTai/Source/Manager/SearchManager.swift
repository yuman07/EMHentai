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
    private var runningInfo: SearchInfo?
    private var waitingRequest: (info: SearchInfo, completion: ([Book], Bool) -> Void)?
    
    func searchWith(info: SearchInfo, completion: @escaping ([Book], Bool) -> Void) {
        let url = info.requestString
        
        do {
            lock.lock()
            defer { lock.unlock() }
            if runningInfo == nil {
                runningInfo = info
            } else if runningInfo!.requestString == url {
                return
            } else if info.pageIndex == 0 || runningInfo!.pageIndex > 0 {
                waitingRequest = (info, completion)
                return
            }
        }
        
        AF.request(url).responseString(queue: .global()) { response in
            switch response.result {
            case .success(let value):
                let target = info.source.rawValue + "g/"
                let ids = value.allIndicesOf(string: target).map { index -> [Substring] in
                    var count = 0
                    let start = value.index(value.startIndex, offsetBy: index + target.count)
                    var end = value.index(after: start)
                    while count < 2 && end < value.endIndex {
                        if value[end] == "/" { count += 1 }
                        end = value.index(after: end)
                    }
                    return value[start..<end].split(separator: "/")
                }
                
                if ids.isEmpty {
                    self.requestFinish(result: ([], false), completion: completion)
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
                ).responseDecodable(of: Gmetadata.self, queue: .global()) { response in
                    switch response.result {
                    case .success(let value):
                        self.requestFinish(result: (value.gmetadata, false), completion: completion)
                    case .failure:
                        self.requestFinish(result: ([], true), completion: completion)
                    }
                }
            case .failure:
                self.requestFinish(result: ([], true), completion: completion)
            }
        }
    }
    
    private func requestFinish(result: ([Book], Bool), completion: @escaping ([Book], Bool) -> Void) {
        lock.lock()
        runningInfo = nil
        if waitingRequest == nil {
            lock.unlock()
            DispatchQueue.main.async {
                completion(result.0, result.1)
            }
        } else {
            let next = waitingRequest!
            waitingRequest = nil
            lock.unlock()
            searchWith(info: next.info, completion: next.completion)
        }
    }
}

private struct Gmetadata: Codable {
    let gmetadata: [Book]
}
