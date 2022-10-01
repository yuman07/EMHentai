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
        case atLeast5
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
    
    static let dbKey = "EMHenTai.SearchInfo.dbKey"
    
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
