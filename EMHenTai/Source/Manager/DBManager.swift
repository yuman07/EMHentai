//
//  DBManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/20.
//

import Foundation

enum DBType: String {
    case history = "111"
    case download = "222"
}

class DBManager {
    static let shared = DBManager()
    private init() {}
    
    private(set) var historyBooks = [Book]()
    private(set) var downloadBooks = [Book]()
    
    func setupDB() {
        
    }
    
    func append(book: Book, at type: DBType) {
        switch type {
        case .history:
            historyBooks.append(book)
        case .download:
            downloadBooks.append(book)
        }
    }
    
    func remove(book: Book, at type: DBType) {
        switch type {
        case .history:
            historyBooks.removeAll { $0.gid == book.gid }
        case .download:
            downloadBooks.removeAll { $0.gid == book.gid }
        }
    }
}
