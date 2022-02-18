//
//  SearchManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import Alamofire

class SearchManager {
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
    
    static let shared = SearchManager()
    private init() {}
    
    private let taskInfo = TaskInfo()
    var searchStartCallback: ((_ searchInfo: SearchInfo) -> Void)?
    var searchFinishCallback: ((_ searchInfo: SearchInfo, _ books: [Book], _ isHappenedNetError: Bool) -> Void)?
    
    func searchWith(info: SearchInfo) {
        Task {
            guard await taskInfo.checkNewInfo(info) else { return }
            
            if info.pageIndex == 0 { info.saveDB() }
            DispatchQueue.main.async {
                self.searchStartCallback?(info)
            }
            
            let value = await p_searchWith(info: info)
            
            if let next = await taskInfo.getNextInfo() {
                searchWith(info: next)
            } else {
                DispatchQueue.main.async {
                    self.searchFinishCallback?(info, value.0, value.1)
                }
            }
        }
    }
    
    private func p_searchWith(info: SearchInfo) async -> ([Book], Bool) {
        guard let value = try? await AF.request(info.requestString).serializingString().value else { return ([], true) }
        
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
        
        guard !ids.isEmpty else { return ([], false) }
        
        guard let value = try? await AF
                .request(info.source.rawValue + "api.php",
                         method: .post,
                         parameters: ["method": "gdata", "gidlist": ids],
                         encoding: JSONEncoding.default)
                .serializingDecodable(Gmetadata.self)
                .value
        else { return ([], true) }
        
        return (value.gmetadata, false)
    }
}

private struct Gmetadata: Codable {
    let gmetadata: [Book]
}
