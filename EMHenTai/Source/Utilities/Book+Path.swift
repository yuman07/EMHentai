//
//  Book+Path.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/19.
//

import Foundation

extension Book {
    private static var downloadFolderPath: String {
        if let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            return path + "/EMDownload"
        } else {
            return NSHomeDirectory() + "/Documents" + "/EMDownload"
        }
    }
    
    var folderPath: String {
        Book.downloadFolderPath + "/\(gid)"
    }
    
    func imagePath(at index: Int) -> String {
        self.folderPath + "/\(gid)-\(index).jpg"
    }
}
