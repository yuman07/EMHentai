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
    var source: SearchSource {
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "SearchInfo_source") }
        get { (UserDefaults.standard.object(forKey: "SearchInfo_source") as? String).flatMap { SearchSource(rawValue: $0) } ?? SearchSource.EHentai }
    }
    var language: SearchLanguage {
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "SearchInfo_language") }
        get { (UserDefaults.standard.object(forKey: "SearchInfo_language") as? String).flatMap { SearchLanguage(rawValue: $0) } ?? SearchLanguage.all }
    }
    var keyWord: String {
        set { UserDefaults.standard.set(newValue, forKey: "SearchInfo_keyWord") }
        get { (UserDefaults.standard.object(forKey: "SearchInfo_keyWord") as? String) ?? "" }
    }
    var rating: Int {
        set { UserDefaults.standard.set(newValue, forKey: "SearchInfo_rating") }
        get { (UserDefaults.standard.object(forKey: "SearchInfo_rating") as? Int) ?? 0 }
    }
    var doujinshi: Bool {
        set { UserDefaults.standard.set(newValue, forKey: "SearchInfo_doujinshi") }
        get { (UserDefaults.standard.object(forKey: "SearchInfo_doujinshi") as? Bool) ?? true }
    }
    var manga: Bool {
        set { UserDefaults.standard.set(newValue, forKey: "SearchInfo_manga") }
        get { (UserDefaults.standard.object(forKey: "SearchInfo_manga") as? Bool) ?? true }
    }
    var artistcg: Bool {
        set { UserDefaults.standard.set(newValue, forKey: "SearchInfo_artistcg") }
        get { (UserDefaults.standard.object(forKey: "SearchInfo_artistcg") as? Bool) ?? true }
    }
    var gamecg: Bool {
        set { UserDefaults.standard.set(newValue, forKey: "SearchInfo_gamecg") }
        get { (UserDefaults.standard.object(forKey: "SearchInfo_gamecg") as? Bool) ?? true }
    }
    var western: Bool {
        set { UserDefaults.standard.set(newValue, forKey: "SearchInfo_western") }
        get { (UserDefaults.standard.object(forKey: "SearchInfo_western") as? Bool) ?? true }
    }
    var non_h: Bool {
        set { UserDefaults.standard.set(newValue, forKey: "SearchInfo_non_h") }
        get { (UserDefaults.standard.object(forKey: "SearchInfo_non_h") as? Bool) ?? true }
    }
    var imageset: Bool {
        set { UserDefaults.standard.set(newValue, forKey: "SearchInfo_imageset") }
        get { (UserDefaults.standard.object(forKey: "SearchInfo_imageset") as? Bool) ?? true }
    }
    var cosplay: Bool {
        set { UserDefaults.standard.set(newValue, forKey: "SearchInfo_cosplay") }
        get { (UserDefaults.standard.object(forKey: "SearchInfo_cosplay") as? Bool) ?? true }
    }
    var asianporn: Bool {
        set { UserDefaults.standard.set(newValue, forKey: "SearchInfo_asianporn") }
        get { (UserDefaults.standard.object(forKey: "SearchInfo_asianporn") as? Bool) ?? true }
    }
    var misc: Bool {
        set { UserDefaults.standard.set(newValue, forKey: "SearchInfo_misc") }
        get { (UserDefaults.standard.object(forKey: "SearchInfo_misc") as? Bool) ?? true }
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
        url += "&f_search=\((keyWord + language.rawValue).split(separator: " ").joined(separator: "+"))"
        url += "&f_apply=Apply+Filter&inline_set=dm_l"
        if rating > 0 { url += "&advsearch=1&f_sname=on&f_stags=on&f_sr=on&f_srdd=\(rating + 1)" }
        if URL(string: url) == nil, let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            url = encodedURL
        }
        return url
    }
}
