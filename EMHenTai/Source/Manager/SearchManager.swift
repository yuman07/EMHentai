//
//  SearchManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import Alamofire

enum SearchSource: String {
    case EHentai = "https://e-hentai.org/"
    case ExHentai = "https://exhentai.org/"
}

struct SearchInfo {
    var source = SearchSource.EHentai
    var keyWord = ""
    var rating = false
    var doujinshi = true
    var manga = true
    var artistcg = true
    var gamecg = true
    var western = true
    var non_h = true
    var imageset = true
    var cosplay = true
    var asianporn = true
    var misc = true
    var chineseOnly = false
    
    func requestStringAt(_ pageIndex: Int) -> String {
        var keyWord = self.keyWord
        if chineseOnly { keyWord += " language:Chinese" }
        keyWord = keyWord.split(separator: " ").joined(separator: "+")
        var url = source.rawValue
        url += "?page=\(pageIndex)"
        url += "&f_doujinshi=\(doujinshi ? 1 : 0)"
        url += "&f_manga=\(manga ? 1 : 0)"
        url += "&f_artistcg=\(artistcg ? 1 : 0)"
        url += "&f_gamecg=\(gamecg ? 1 : 0)"
        url += "&f_western=\(western ? 1 : 0)"
        url += "&f_non-h=\(non_h ? 1 : 0)"
        url += "&f_imageset=\(imageset ? 1 : 0)"
        url += "&f_cosplay=\(cosplay ? 1 : 0)"
        url += "&f_asianporn=\(asianporn ? 1 : 0)"
        url += "&f_misc=\(misc ? 1 : 0)"
        url += "&f_search=\(keyWord)"
        url += "&f_apply=Apply+Filter&inline_set=dm_l"
        if rating { url += "&advsearch=1&f_sname=on&f_stags=on&f_sr=on&f_srdd=1" }
        return url
    }
}

class SearchManager {
    static let shared = SearchManager()
    static let serialQueue = DispatchQueue(label: "com.SearchManager.EMHenTai")
    private init() {}
    
    func searchWith(info: SearchInfo, pageIndex: Int, completion: @escaping ([Book]) -> Void) {
        AF.request(info.requestStringAt(pageIndex)).responseString(queue: SearchManager.serialQueue) { response in
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
                    DispatchQueue.main.async {
                        completion([])
                    }
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
                ).responseJSON(queue: SearchManager.serialQueue) { response in
                    switch response.result {
                    case .success(let value):
                        guard let value = value as? [String: Any], let content = value["gmetadata"] as? [Any] else {
                            DispatchQueue.main.async {
                                completion([])
                            }
                            return
                        }
                        
                        var result = [Book]()
                        for obj in content {
                            if let data = try? JSONSerialization.data(withJSONObject: obj, options: []),
                               let book = try? JSONDecoder().decode(Book.self, from: data) {
                                result.append(book)
                            }
                        }
                        DispatchQueue.main.async {
                            completion(result)
                        }
                    case .failure:
                        DispatchQueue.main.async {
                            completion([])
                        }
                    }
                }
                
            case .failure:
                DispatchQueue.main.async {
                    completion([])
                }
            }
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
