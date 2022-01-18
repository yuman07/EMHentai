//
//  SettingManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/18.
//

import Foundation

class SettingManager {
    static let shared = SettingManager()
    private init() {}
    
    var searchSource: String {
        set { UserDefaults.standard.set(newValue, forKey: "SettingManager_searchSource") }
        get { (UserDefaults.standard.object(forKey: "SettingManager_searchSource") as? String) ?? SearchSource.EHentai.rawValue }
    }
}
