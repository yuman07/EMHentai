//
//  SearchManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import Alamofire

protocol SearchManagerCallbackDelegate: AnyObject {
    func searchStartCallback(searchInfo: SearchInfo)
    func searchFinishCallback(searchInfo: SearchInfo, result: Result<[Book], SearchManager.SearchError>)
}

final actor SearchManager {
    enum SearchError: String, Error {
        case netError
        case ipError = "Your IP address has been temporarily banned for excessive pageloads"
    }
    
    static let shared = SearchManager()
    private init() {}
    
    @MainActor
    weak var delegate: SearchManagerCallbackDelegate?
    
    private var currentTask: Task<Void, Never>?
    
    nonisolated func searchWith(info: SearchInfo) {
        Task { await p_searchWith(info: info) }
    }
    
    private func p_searchWith(info: SearchInfo) {
        guard info.pageIndex == 0 || currentTask == nil else {
            return
        }
        
        currentTask?.cancel()
        
        currentTask = Task {
            await MainActor.run { delegate?.searchStartCallback(searchInfo: info) }
            guard !Task.isCancelled else { return }
            
            let result = await pp_searchWith(info: info)
            guard !Task.isCancelled else { return }
            
            currentTask = nil
            await MainActor.run { delegate?.searchFinishCallback(searchInfo: info, result: result) }
        }
    }
    
    private nonisolated func pp_searchWith(info: SearchInfo) async -> Result<[Book], SearchError> {
        guard let value = try? await AF.request(info.requestString, interceptor: RetryPolicy()).serializingString(automaticallyCancelling: true).value else {
            return .failure(.netError)
        }
        guard !value.contains(SearchError.ipError.rawValue) else { return .failure(.ipError) }
        
        let ids = value
            .allSubStringOf(target: info.source.rawValue + "g/", endCharater: "/", count: 2)
            .map { $0.split(separator: "/") }
            .filter { $0.count == 2 }
        guard !ids.isEmpty else { return .success([]) }
        
        guard let value = try? await AF
            .request(info.source.rawValue + "api.php",
                     method: .post,
                     parameters: ["method": "gdata", "gidlist": ids],
                     encoding: JSONEncoding.default)
                .serializingDecodable(Gmetadata.self, automaticallyCancelling: true).value else { return .failure(.netError) }
        
        return .success(value.gmetadata)
    }
}

private struct Gmetadata: Codable {
    let gmetadata: [Book]
}
