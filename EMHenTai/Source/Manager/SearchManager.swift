//
//  SearchManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import Alamofire

protocol SearchManagerCallbackDelegate: AnyObject {
    func searchStartCallback(searchInfo: SearchInfo) async
    func searchFinishCallback(searchInfo: SearchInfo, result: Result<[Book], SearchError>) async
}

enum SearchError: Error {
    case netError
}

private actor TaskInfo {
    var runningInfo: SearchInfo?
    var waitingInfo: SearchInfo?
    
    func checkNewInfo(_ info: SearchInfo) -> Bool {
        guard let runningInfo = runningInfo else {
            self.runningInfo = info
            return true
        }
        guard runningInfo.requestString != info.requestString else { return false }
        
        if (info.pageIndex == 0) || (runningInfo.pageIndex > 0 && (waitingInfo == nil || waitingInfo!.pageIndex > 0)) {
            self.waitingInfo = info
            return false
        }
        
        return false
    }
    
    func getNextInfo() -> SearchInfo? {
        runningInfo = nil
        if let next = waitingInfo {
            waitingInfo = nil
            return next
        }
        return nil
    }
}

class SearchManager {
    static let shared = SearchManager()
    private init() {}
    
    private let taskInfo = TaskInfo()
    
    weak var delegate: SearchManagerCallbackDelegate?
    
    func searchWith(info: SearchInfo) {
        Task {
            guard await taskInfo.checkNewInfo(info) else { return }
            
            if info.pageIndex == 0 { info.saveDB() }
            await delegate?.searchStartCallback(searchInfo: info)
            
            let result = await p_searchWith(info: info)
            
            if let next = await taskInfo.getNextInfo() {
                searchWith(info: next)
            } else {
                await delegate?.searchFinishCallback(searchInfo: info, result: result)
            }
        }
    }
    
    private func p_searchWith(info: SearchInfo) async -> Result<[Book], SearchError> {
        guard let value = try? await AF.request(info.requestString).serializingString().value else { return .failure(.netError) }
        
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
        
        guard !ids.isEmpty else { return .success([]) }
        
        guard let value = try? await AF
                .request(info.source.rawValue + "api.php",
                         method: .post,
                         parameters: ["method": "gdata", "gidlist": ids],
                         encoding: JSONEncoding.default)
                .serializingDecodable(Gmetadata.self)
                .value
        else { return .failure(.netError) }
        
        return .success(value.gmetadata)
    }
}

private struct Gmetadata: Codable {
    let gmetadata: [Book]
}
