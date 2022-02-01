//
//  SearchInfo.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation

enum SearchSource: String, CaseIterable {
    case EHentai = "https://e-hentai.org/"
    case ExHentai = "https://exhentai.org/"
}

enum SearchLanguage: String, CaseIterable {
    case all = ""
    case chinese = " language:Chinese"
    case english = " language:English"
}

struct SearchInfo {
    var pageIndex = 0
    var source = (UserDefaults.standard.object(forKey: "SearchInfo_source") as? String).flatMap { SearchSource(rawValue: $0) } ?? SearchSource.EHentai
    var language = (UserDefaults.standard.object(forKey: "SearchInfo_language") as? String).flatMap { SearchLanguage(rawValue: $0) } ?? SearchLanguage.all
    var keyWord = (UserDefaults.standard.object(forKey: "SearchInfo_keyWord") as? String) ?? ""
    var rating = (UserDefaults.standard.object(forKey: "SearchInfo_rating") as? Int) ?? 0
    var doujinshi = (UserDefaults.standard.object(forKey: "SearchInfo_doujinshi") as? Bool) ?? true
    var manga = (UserDefaults.standard.object(forKey: "SearchInfo_manga") as? Bool) ?? true
    var artistcg = (UserDefaults.standard.object(forKey: "SearchInfo_artistcg") as? Bool) ?? true
    var gamecg = (UserDefaults.standard.object(forKey: "SearchInfo_gamecg") as? Bool) ?? true
    var western = (UserDefaults.standard.object(forKey: "SearchInfo_western") as? Bool) ?? true
    var non_h = (UserDefaults.standard.object(forKey: "SearchInfo_non_h") as? Bool) ?? true
    var imageset = (UserDefaults.standard.object(forKey: "SearchInfo_imageset") as? Bool) ?? true
    var cosplay = (UserDefaults.standard.object(forKey: "SearchInfo_cosplay") as? Bool) ?? true
    var asianporn = (UserDefaults.standard.object(forKey: "SearchInfo_asianporn") as? Bool) ?? true
    var misc = (UserDefaults.standard.object(forKey: "SearchInfo_misc") as? Bool) ?? true
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
        url += "&f_search=\((keyWord + language.rawValue).split(separator: " ").map({ TranslateManager.shared.translateCn(cn: "\($0)") }).joined(separator: "+"))"
        url += "&f_apply=Apply+Filter&inline_set=dm_l"
        if rating > 0 { url += "&advsearch=1&f_sname=on&f_stags=on&f_sr=on&f_srdd=\(rating + 1)" }
        if URL(string: url) == nil, let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            url = encodedURL
        }
        return url
    }
    
    func saveDB() {
        UserDefaults.standard.set(source.rawValue, forKey: "SearchInfo_source")
        UserDefaults.standard.set(language.rawValue, forKey: "SearchInfo_language")
        UserDefaults.standard.set(keyWord, forKey: "SearchInfo_keyWord")
        UserDefaults.standard.set(rating, forKey: "SearchInfo_rating")
        UserDefaults.standard.set(doujinshi, forKey: "SearchInfo_doujinshi")
        UserDefaults.standard.set(manga, forKey: "SearchInfo_manga")
        UserDefaults.standard.set(artistcg, forKey: "SearchInfo_artistcg")
        UserDefaults.standard.set(gamecg, forKey: "SearchInfo_gamecg")
        UserDefaults.standard.set(western, forKey: "SearchInfo_western")
        UserDefaults.standard.set(non_h, forKey: "SearchInfo_non_h")
        UserDefaults.standard.set(imageset, forKey: "SearchInfo_imageset")
        UserDefaults.standard.set(cosplay, forKey: "SearchInfo_cosplay")
        UserDefaults.standard.set(asianporn, forKey: "SearchInfo_asianporn")
        UserDefaults.standard.set(misc, forKey: "SearchInfo_misc")
    }
}
