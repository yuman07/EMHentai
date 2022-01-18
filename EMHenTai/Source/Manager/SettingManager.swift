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
    
    var currentSearchSource: String {
        set { UserDefaults.standard.set(newValue, forKey: "SettingManager_currentSearchSource") }
        get { (UserDefaults.standard.object(forKey: "SettingManager_currentSearchSource") as? String) ?? SearchSource.EHentai.rawValue }
    }
}
