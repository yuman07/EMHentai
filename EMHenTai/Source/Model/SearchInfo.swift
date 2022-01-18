//
//  SearchInfo.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation

enum SearchSource: String {
    case EHentai = "https://e-hentai.org/"
    case ExHentai = "https://exhentai.org/"
}

struct SearchInfo {
    var source = SettingManager.shared.currentSearchSource
    var keyWord = "王都"
    var rating: Bool {
        set { UserDefaults.standard.set(newValue, forKey: "SearchInfo_rating") }
        get { (UserDefaults.standard.object(forKey: "SearchInfo_rating") as? Bool) ?? true }
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
    var chineseOnly: Bool {
        set { UserDefaults.standard.set(newValue, forKey: "SearchInfo_chineseOnly") }
        get { (UserDefaults.standard.object(forKey: "SearchInfo_chineseOnly") as? Bool) ?? true }
    }
    var pageIndex = 0
}

extension SearchInfo {
    var requestString: String {
        var keyWord = self.keyWord + (chineseOnly ? " language:Chinese" : "")
        keyWord = keyWord.split(separator: " ").joined(separator: "+")
        var url = source
        url += "?page=\(pageIndex)"
        url += "&f_doujinshi=\(doujinshi)"
        url += "&f_manga=\(manga)"
        url += "&f_artistcg=\(artistcg)"
        url += "&f_gamecg=\(gamecg)"
        url += "&f_western=\(western)"
        url += "&f_non-h=\(non_h)"
        url += "&f_imageset=\(imageset)"
        url += "&f_cosplay=\(cosplay)"
        url += "&f_asianporn=\(asianporn)"
        url += "&f_misc=\(misc)"
        url += "&f_search=\(keyWord)"
        url += "&f_apply=Apply+Filter&inline_set=dm_l"
        if rating { url += "&advsearch=1&f_sname=on&f_stags=on&f_sr=on&f_srdd=1" }
        if URL(string: url) == nil, let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            url = encodedURL
        }
        return url
    }
}
