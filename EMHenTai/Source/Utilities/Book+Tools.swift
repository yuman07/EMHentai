//
//  Book+Tools.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/19.
//

import Foundation

// https://ehwiki.org/wiki/Technical_Issues  "Content Warning - This gallery has been flagged as Offensive For Everyone
private let offensiveTags = ["guro", "snuff", "scat"]

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
    
    var currentWebURLString: String {
        "\(SearchInfo.currentSource.rawValue)g/\(gid)/\(token)/"
    }
    
    func webURLString(with source: SearchInfo.Source) -> String {
        "\(source.rawValue)g/\(gid)/\(token)/"
    }
    
    var fileCountNum: Int {
        Int(filecount) ?? 0
    }
    
    var downloadedFileCount: Int {
        (try? FileManager.default.contentsOfDirectory(atPath: folderPath))?.count ?? 0
    }
    
    var isOffensive: Bool {
        for tag in tags {
            if offensiveTags.contains(tag.lowercased()) { return true }
        }
        return false
    }
}
