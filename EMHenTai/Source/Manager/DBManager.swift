//
//  DBManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/20.
//

import Foundation
import CoreData
import UIKit

enum DBType: String {
    case history = "HistoryBook"
    case download = "DownloadBook"
}

class DBManager {
    static let shared = DBManager()
    private init() {}
    
    var context: NSManagedObjectContext {
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    private(set) lazy var historyBooks: [Book] = {
        var books = [Book]()
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: DBType.history.rawValue)
        if let objs = try? context.fetch(request) as? [NSManagedObject] {
            books = objs.map { bookFrom(obj: $0) }.reversed()
        }
        return books
    }()
    
    private(set) lazy var downloadBooks: [Book] = {
        var books = [Book]()
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: DBType.download.rawValue)
        if let result = try? context.fetch(request) as? [NSManagedObject] {
            books = result.map { bookFrom(obj: $0) }.reversed()
        }
        return books
    }()
    
    func insertIfNotExist(book: Book, at type: DBType) {
        switch type {
        case .history:
            historyBooks.insert(book, at: 0)
        case .download:
            downloadBooks.insert(book, at: 0)
        }
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: type.rawValue)
        request.predicate = NSPredicate(format: "gid = %d", book.gid)
        let isExist = ((try? context.fetch(request) as? [NSManagedObject]).map { $0.count > 0 }) ?? false
        if !isExist {
            let obj = NSEntityDescription.insertNewObject(forEntityName: type.rawValue, into: context)
            update(obj: obj, with: book)
            saveDB()
        }
    }
    
    func remove(book: Book, at type: DBType) {
        switch type {
        case .history:
            historyBooks.removeAll { $0.gid == book.gid }
        case .download:
            downloadBooks.removeAll { $0.gid == book.gid }
        }
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: type.rawValue)
        request.predicate = NSPredicate(format: "gid = %d", book.gid)
        if let objs = try? context.fetch(request) as? [NSManagedObject] {
            for obj in objs { context.delete(obj) }
            saveDB()
        }
    }
    
    func removeAll(type: DBType) {
        switch type {
        case .history:
            historyBooks.removeAll()
        case .download:
            downloadBooks.removeAll()
        }
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: type.rawValue)
        if let objs = try? context.fetch(request) as? [NSManagedObject] {
            for obj in objs { context.delete(obj) }
            saveDB()
        }
    }
    
    private func saveDB() {
        if context.hasChanges {
            try? context.save()
        }
    }
    
    private func bookFrom(obj: NSManagedObject) -> Book {
        var torrents = [Torrent]()
        if let data = (obj.value(forKey: "torrents") as? String ?? "").data(using: .utf8), let ts = try? JSONDecoder().decode([Torrent].self, from: data) {
            torrents = ts
        }
        return Book(gid: obj.value(forKey: "gid") as? Int ?? 0,
                    title: obj.value(forKey: "title") as? String ?? "",
                    title_jpn: obj.value(forKey: "title_jpn") as? String ?? "",
                    category: obj.value(forKey: "category") as? String ?? "",
                    thumb: obj.value(forKey: "thumb") as? String ?? "",
                    uploader: obj.value(forKey: "uploader") as? String ?? "",
                    filecount: obj.value(forKey: "filecount") as? String ?? "",
                    filesize: obj.value(forKey: "filesize") as? Int ?? 0,
                    tags: (obj.value(forKey: "tags") as? String ?? "").components(separatedBy: ","),
                    token: obj.value(forKey: "token") as? String ?? "",
                    rating: obj.value(forKey: "rating") as? String ?? "",
                    archiver_key: obj.value(forKey: "archiver_key") as? String ?? "",
                    posted: obj.value(forKey: "posted") as? String ?? "",
                    expunged: obj.value(forKey: "expunged") as? Bool ?? false,
                    torrentcount: obj.value(forKey: "torrentcount") as? String ?? "",
                    torrents: torrents)
    }
    
    private func update(obj: NSManagedObject, with book: Book) {
        obj.setValue(book.gid, forKey: "gid")
        obj.setValue(book.title, forKey: "title")
        obj.setValue(book.title_jpn, forKey: "title_jpn")
        obj.setValue(book.category, forKey: "category")
        obj.setValue(book.thumb, forKey: "thumb")
        obj.setValue(book.uploader, forKey: "uploader")
        obj.setValue(book.filecount, forKey: "filecount")
        obj.setValue(book.filesize, forKey: "filesize")
        obj.setValue(book.tags.joined(separator: ","), forKey: "tags")
        obj.setValue(book.token, forKey: "token")
        obj.setValue(book.rating, forKey: "rating")
        obj.setValue(book.archiver_key, forKey: "archiver_key")
        obj.setValue(book.posted, forKey: "posted")
        obj.setValue(book.expunged, forKey: "expunged")
        obj.setValue(book.torrentcount, forKey: "torrentcount")
        if let data = try? JSONEncoder().encode(book.torrents), let str = String(data: data, encoding: .utf8) {
            obj.setValue(str, forKey: "torrents")
        } else {
            obj.setValue("", forKey: "torrents")
        }
    }
}
