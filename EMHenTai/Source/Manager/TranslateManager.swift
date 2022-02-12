//
//  TranslateManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/24.
//

import Foundation

class TranslateManager {
    static let shared = TranslateManager()
    private static let jsonName = "tag-v6.3917.1.json"    // https://github.com/EhTagTranslation/Database/releases    db.text.json
    private init () {
        guard let url = Bundle.main.url(forResource: TranslateManager.jsonName, withExtension: nil),
              let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let content = obj["data"] as? [[String: Any]] else { return }
        
        for dic in content {
            guard let namespace = dic["namespace"] as? String, namespace != "rows",
                  let data = dic["data"] as? [String: [String: String]] else { continue }
            
            for (key, value) in data {
                guard !key.isEmpty, let name = value["name"], !name.isEmpty, key.lowercased() != name.lowercased() else { continue }
                dictEn[key] = name
                dictCn[name] = key
            }
        }
    }
    
    private var dictEn = [String: String]()
    private var dictCn = [String: String]()
    
    func translateEn(_ en: String) -> String {
        guard let value = dictEn[en] else { return "" }
        return "(\(value))"
    }
    
    func translateCn(_ cn: String) -> String {
        dictCn[cn] ?? cn
    }
}
