//
//  FilePathHelper.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/18.
//

import Foundation

struct FilePathHelper {
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
    
    static func bookFolderPath(of book: Book) -> String {
        self.downloadFolderPath() + "/\(book.gid)"
    }
    
    static func imagePath(of book:Book, at index: Int) -> String {
        let imageName = "/\(book.gid)-\(index).jpg"
        return self.bookFolderPath(of: book) + imageName
    }
}
