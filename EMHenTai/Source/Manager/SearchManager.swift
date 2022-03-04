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
    func searchFinishCallback(searchInfo: SearchInfo, result: Result<[Book], SearchManager.SearchError>) async
}

final class SearchManager {
    enum SearchError: String, Error {
        case netError
        case ipError = "Your IP address has been temporarily banned for excessive pageloads"
    }
    
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
            
            if let next = await taskInfo.nextInfo() {
                searchWith(info: next)
            } else {
                await delegate?.searchFinishCallback(searchInfo: info, result: result)
            }
        }
    }
    
    private func p_searchWith(info: SearchInfo) async -> Result<[Book], SearchError> {
        guard let value = try? await AF.request(info.requestString).serializingString().value else { return .failure(.netError) }
        guard !value.contains(SearchError.ipError.rawValue) else { return .failure(.ipError) }
        
        let ids = value.allSubStringOf(target: info.source.rawValue + "g/", endCharater: "/", count: 2).map { $0.split(separator: "/") }
        guard !ids.isEmpty else { return .success([]) }
        
        guard let value = try? await AF
                .request(info.source.rawValue + "api.php",
                         method: .post,
                         parameters: ["method": "gdata", "gidlist": ids],
                         encoding: JSONEncoding.default)
                .serializingDecodable(Gmetadata.self).value else { return .failure(.netError) }
        
        return .success(value.gmetadata)
    }
}

final private actor TaskInfo {
    private var runningInfo: SearchInfo?
    private var waitingInfo: SearchInfo?
    
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
    
    func nextInfo() -> SearchInfo? {
        runningInfo = nil
        if let next = waitingInfo {
            waitingInfo = nil
            return next
        }
        return nil
    }
}

private struct Gmetadata: Codable {
    let gmetadata: [Book]
}
