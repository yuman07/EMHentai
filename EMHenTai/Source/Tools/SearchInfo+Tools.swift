//
//  SearchInfo+Tools.swift
//  EMHenTai
//
//  Created by yuman on 2022/10/1.
//

import Foundation

extension SearchInfo {
    var requestString: String {
        var url = source.rawValue + "/?"
        url += "f_search=\((keyWord + language.rawValue).components(separatedBy: " ").map({ TranslateManager.shared.translateCn($0) }).joined(separator: "+"))"
        Category.allCases.forEach { url += "&f_\($0.rawValue)=\(categories.contains($0) ? 1 : 0)" }
        if !lastGid.isEmpty { url += "&next=\(lastGid)" }
        if rating.rawValue > 0 { url += "&advsearch=1&f_srdd=\(rating.rawValue + 1)" }
        return url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url
    }
    
    func saveDB() {
        if let data = try? JSONEncoder().encode(self) {
            SearchInfo.currentSource = source
            UserDefaults.standard.set(data, forKey: SearchInfo.dbKey)
        }
    }
}

extension SearchInfo.Source: SearchVCItemDataSource {
    var searchItemTitle: String {
        switch self {
        case .EHentai:
            return "E-Hentai"
        case .ExHentai:
            return "ExHentai" + (SettingManager.shared.isLoginSubject.value ? "" : "(登录后可用)")
        }
    }
}

extension SearchInfo.Language: SearchVCItemDataSource {
    var searchItemTitle: String {
        switch self {
        case .all:
            return "不限"
        case .chinese:
            return "中文"
        }
    }
}

extension SearchInfo.Rating: SearchVCItemDataSource {
    var searchItemTitle: String {
        switch self {
        case .all:
            return "不限"
        case .atLeast2:
            return "至少2星"
        case .atLeast3:
            return "至少3星"
        case .atLeast4:
            return "至少4星"
        case .atLeast5:
            return "满星"
        }
    }
}

extension SearchInfo.Category: SearchVCItemDataSource {
    var searchItemTitle: String {
        switch self {
        case .doujinshi:
            return "Doujinshi"
        case .manga:
            return "Manga"
        case .artistcg:
            return "Artist CG"
        case .gamecg:
            return "Game CG"
        case .western:
            return "Western"
        case .non_h:
            return "Non-H"
        case .imageset:
            return "Image Set"
        case .cosplay:
            return "Cosplay"
        case .asianporn:
            return "Asian Porn"
        case .misc:
            return "Misc"
        }
    }
}
