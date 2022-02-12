//
//  Book+Tools.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/19.
//

import Foundation

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
    
    var showTitle: String {
        title_jpn.isEmpty ? title : title_jpn
    }
    
    var originWebURLString: String {
        "\(SearchInfo.currentSource.rawValue)g/\(gid)/\(token)/"
    }
    
    var fileCountNum: Int {
        Int(filecount) ?? 0
    }
    
    var downloadedFileCount: Int {
        (try? FileManager.default.contentsOfDirectory(atPath: folderPath))?.count ?? 0
    }
}
