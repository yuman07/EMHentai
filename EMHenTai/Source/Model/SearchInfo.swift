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
    var source = SearchSource.EHentai.rawValue
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
    var pageIndex = 0
    
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
        return url
    }
}
