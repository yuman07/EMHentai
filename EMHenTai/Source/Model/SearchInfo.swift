//
//  SearchInfo.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation

struct SearchInfo: Codable {
    enum Source: String, CaseIterable, Codable {
        case EHentai = "https://e-hentai.org/"
        case ExHentai = "https://exhentai.org/"
    }
    
    enum Language: String, CaseIterable, Codable {
        case all = ""
        case chinese = " language:Chinese"
    }
    
    static var currentSource = {
        SearchInfo().source
    }()
    
    var pageIndex = 0
    var source = Source.EHentai
    var language = Language.all
    var keyWord = ""
    var rating = 0
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
    
    init() {
        if let data = UserDefaults.standard.object(forKey: "EMHenTai.SearchInfo.shared") as? Data,
           let info = try? JSONDecoder().decode(SearchInfo.self, from: data) {
            self = info
        }
    }
}

extension SearchInfo {
    var requestString: String {
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
        url += "&f_search=\((keyWord + language.rawValue).split(separator: " ").map({ TranslateManager.shared.translateCn("\($0)") }).joined(separator: "+"))"
        url += "&f_apply=Apply+Filter&inline_set=dm_l"
        if rating > 0 { url += "&advsearch=1&f_sname=on&f_stags=on&f_sr=on&f_srdd=\(rating + 1)" }
        return url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url
    }
    
    func saveDB() {
        if let data = try? JSONEncoder().encode(self) {
            SearchInfo.currentSource = self.source
            UserDefaults.standard.set(data, forKey: "EMHenTai.SearchInfo.shared")
        }
    }
}
