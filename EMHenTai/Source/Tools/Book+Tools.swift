//
//  Book+Tools.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/19.
//

import Foundation

extension Book {
    private enum Constant {
        // https://ehwiki.org/wiki/Technical_Issues  "Content Warning - This gallery has been flagged as Offensive For Everyone
        static let offensiveTags = Set(["guro", "snuff", "scat"])
    }
    
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
    
    var contentImgCount: Int {
        Int(filecount) ?? 0
    }
    
    var downloadedImgCount: Int {
        (try? FileManager.default.contentsOfDirectory(atPath: folderPath))?.count ?? 0
    }
    
    var isOffensive: Bool {
        !Constant.offensiveTags.intersection(Set(tags)).isEmpty
    }
}
