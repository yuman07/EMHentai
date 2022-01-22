//
//  Book+Tools.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/19.
//

import Foundation

extension Book {
    var showTitle: String {
        if SettingManager.shared.currentLanguage == .english {
            return title.isEmpty ? title_jpn : title
        }
        return title_jpn.isEmpty ? title : title_jpn
    }
}

extension Book {
    static var downloadFolderPath: String {
        NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first.flatMap { $0 + "/EMDownload" } ?? NSHomeDirectory() + "/Documents/EMDownload"
    }
    
    var folderPath: String {
        Book.downloadFolderPath + "/\(gid)"
    }
    
    func imagePath(at index: Int) -> String {
        folderPath + "/\(gid)-\(index).jpg"
    }
    
    var fileCountNum: Int {
        Int(filecount) ?? 0
    }
    
    var downloadedFileCount: Int {
        (try? FileManager.default.contentsOfDirectory(atPath: folderPath))?.count ?? 0
    }
}
