//
//  TranslateManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/24.
//

import Foundation

class TranslateManager {
    static let shared = TranslateManager()
    private init () {}
    
    private static let jsonName = "tag-v6.3917.1.json"
    
    private let dict: [String: String] = {
        var map = [String: String]()
        guard let url = Bundle.main.url(forResource: TranslateManager.jsonName, withExtension: nil) else { return map }
        guard let data = try? Data(contentsOf: url) else { return map }
        guard let obj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return map }
        guard let content = obj["data"] as? [[String: Any]] else { return map }
        
        for dic in content {
            guard let namespace = dic["namespace"] as? String, namespace != "rows" else { continue }
            guard let data = dic["data"] as? [String: [String: String]] else { continue }
            for (key, value) in data {
                guard !key.isEmpty else { continue }
                guard let name = value["name"], !name.isEmpty, key.lowercased() != name.lowercased() else { continue }
                map[key] = name
            }
        }
        
        return map
    }()
    
    func translate(word: String) -> String {
        guard let value = dict[word] else { return "" }
        return "(\(value))"
    }
}
