//
//  SearchManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Alamofire
import Combine

final actor SearchManager {
    enum SearchEvent {
        case start(info: SearchInfo)
        case finish(info: SearchInfo, result: Result<[Book], SearchManager.Error>)
    }
    
    enum Error: String, Swift.Error {
        case netError
        case ipError = "Your IP address has been temporarily banned for excessive pageloads"
    }
    
    static let shared = SearchManager()
    private init() {}
    
    private var currentTask: Task<Void, Never>?
    
    nonisolated let eventSubject = PassthroughSubject<SearchEvent, Never>()
    
    nonisolated func searchWith(info: SearchInfo) {
        Task { await p_searchWith(info: info) }
    }
    
    private func p_searchWith(info: SearchInfo) {
        guard info.lastGid.isEmpty || currentTask == nil else {
            return
        }
        
        currentTask?.cancel()
        
        currentTask = Task {
            eventSubject.send(.start(info: info))
            
            let result = await pp_searchWith(info: info)
            
            if !Task.isCancelled {
                eventSubject.send(.finish(info: info, result: result))
            }
            
            currentTask = nil
        }
    }
    
    private nonisolated func pp_searchWith(info: SearchInfo) async -> Result<[Book], Error> {
        guard let value = try? await AF.request(info.requestString, interceptor: RetryPolicy()).serializingString(automaticallyCancelling: true).value else {
            return .failure(.netError)
        }
        guard !value.contains(Error.ipError.rawValue) else { return .failure(.ipError) }
        
        let ids = value
            .allSubString(of: info.source.rawValue + "g/", endCharater: "/", count: 2)
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
