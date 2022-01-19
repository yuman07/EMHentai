//
//  Book+Path.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/19.
//

import Foundation

extension Book {
    static private func documentFolderPath() -> String {
        if let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            return path
        } else {
            return NSHomeDirectory() + "/Documents"
        }
    }
    
    static private func downloadFolderPath() -> String {
        self.documentFolderPath() + "/EMDownload"
    }
    
    var folderPath: String {
        Book.downloadFolderPath() + "/\(gid)"
    }
    
    func imagePath(at index: Int) -> String {
        self.folderPath + "/\(gid)-\(index).jpg"
    }
}
