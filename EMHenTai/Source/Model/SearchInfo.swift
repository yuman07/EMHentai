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
    
    enum Rating: Int, CaseIterable, Codable {
        case all
        case atLeast2
        case atLeast3
        case atLeast4
    }
    
    enum Category: String, CaseIterable, Codable {
        case doujinshi
        case manga
        case artistcg
        case gamecg
        case western
        case non_h = "non-h"
        case imageset
        case cosplay
        case asianporn
        case misc
    }
    
    private static let dbKey = "EMHenTai.SearchInfo.dbKey"
    
    static var currentSource = SearchInfo().source
    
    var pageIndex = 0
    var keyWord = ""
    var source = Source.EHentai
    var language = Language.all
    var rating = Rating.all
    var categories = Category.allCases
    
    init() {
        if let data = UserDefaults.standard.object(forKey: SearchInfo.dbKey) as? Data,
           let info = try? JSONDecoder().decode(SearchInfo.self, from: data) {
            self = info
        }
        pageIndex = 0
    }
}

extension SearchInfo {
    var requestString: String {
        var url = source.rawValue + "?page=\(pageIndex)"
        Category.allCases.forEach { url += "&f_\($0.rawValue)=\(categories.contains($0) ? 1 : 0)" }
        url += "&f_search=\((keyWord + language.rawValue).split(separator: " ").map({ TranslateManager.shared.translateCn("\($0)") }).joined(separator: "+"))"
        if rating.rawValue > 0 { url += "&advsearch=1&f_sname=on&f_stags=on&f_sr=on&f_srdd=\(rating.rawValue + 1)" }
        return url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url
    }
    
    func saveDB() {
        if let data = try? JSONEncoder().encode(self) {
            SearchInfo.currentSource = self.source
            UserDefaults.standard.set(data, forKey: SearchInfo.dbKey)
        }
    }
}

extension SearchInfo.Source: searchVCItemDataSource {
    var searchItemTitle: String {
        switch self {
        case .EHentai:
            return "E-Hentai"
        case .ExHentai:
            return "ExHentai" + (SettingManager.shared.isLogin ? "" : "(登录后可用)")
        }
    }
}

extension SearchInfo.Language: searchVCItemDataSource {
    var searchItemTitle: String {
        switch self {
        case .all:
            return "不限"
        case .chinese:
            return "中文"
        }
    }
}

extension SearchInfo.Rating: searchVCItemDataSource {
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
        }
    }
}

extension SearchInfo.Category: searchVCItemDataSource {
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
