//
//  Book+Tools.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/19.
//

import Foundation

// https://ehwiki.org/wiki/Technical_Issues  "Content Warning - This gallery has been flagged as Offensive For Everyone
private let offensiveTags = Set(["guro", "snuff", "scat"])

extension Book {
    static var downloadFolderPath: String {
        NSHomeDirectory() + "/Documents/EMDownload"
    }
    
    var folderPath: String {
        "\(Book.downloadFolderPath)/\(gid)"
    }
    
    func imagePath(at index: Int) -> String {
        "\(folderPath)/\(gid)-\(index).jpg"
    }
    
    var coverImagePath: String {
        "\(folderPath)/\(gid)-cover.jpg"
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
        !offensiveTags.intersection(Set(tags)).isEmpty
    }
}
