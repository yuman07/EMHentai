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
        Task { @SearchManagerActor in
            await checkSearchWith(info: info)
        }
    }
    
    private func checkSearchWith(info: SearchInfo) {
        guard info.lastGid.isEmpty || currentTask == nil else {
            return
        }
        
        currentTask?.cancel()
        
        currentTask = Task {
            guard !Task.isCancelled else { return }
            
            eventSubject.send(.start(info: info))
            
            let result = await startSearchWith(info: info)
            
            guard !Task.isCancelled else { return }
            
            eventSubject.send(.finish(info: info, result: result))
            
            currentTask = nil
        }
    }
    
    private nonisolated func startSearchWith(info: SearchInfo) async -> Result<[Book], Error> {
        guard let value = try? await emSession.request(info.requestString, interceptor: RetryPolicy()).serializingString().value else {
            return .failure(.netError)
        }
        guard !value.contains(Error.ipError.rawValue) else { return .failure(.ipError) }
        
        let ids = value
            .allSubString(of: info.source.rawValue + "g/", endCharater: "/", count: 2)
            .map { $0.split(separator: "/") }
            .filter { $0.count == 2 }
        guard !ids.isEmpty else { return .success([]) }
        
        guard let value = try? await emSession
            .request(
                info.source.rawValue + "api.php",
                method: .post,
                parameters: ["method": "gdata", "gidlist": ids],
                encoding: JSONEncoding.default,
                interceptor: RetryPolicy()
            )
                .serializingDecodable(Gmetadata.self)
                .value
        else { return .failure(.netError) }
        
        return .success(value.gmetadata.compactMap({ Book($0) }))
    }
}

@globalActor private actor SearchManagerActor {
    static let shared = SearchManagerActor()
}

private struct Gmetadata: Codable {
    let gmetadata: [BookDto]
}

private struct BookDto: Codable {
    let gid: Int?
    let title: String?
    let title_jpn: String?
    let category: String?
    let thumb: String?
    let filecount: String?
    let tags: [String?]?
    let token: String?
    let rating: String?
}

private extension Book {
    init?(_ dto: BookDto) {
        guard let gid = dto.gid else { return nil }
        self.init(
            gid: gid,
            title: dto.title,
            titleJpn: dto.title_jpn,
            category: dto.category,
            thumb: dto.thumb,
            fileCount: Int(dto.filecount ?? "0") ?? 0,
            tags: (dto.tags ?? []).compactMap({ $0 }),
            token: dto.token,
            rating: dto.rating
        )
    }
}
