//
//  DBManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/20.
//

import Foundation
import CoreData
import UIKit

final class DBManager {
    enum DBType: String, CaseIterable {
        case history = "HistoryBook"
        case download = "DownloadBook"
    }
    
    static let shared = DBManager()
    private init() {}
    
    var context: NSManagedObjectContext!
    
    private let lock = NSLock()
    private var queue = DispatchQueue(label: "EMHenTai.DBManager.SerialQueue")
    private lazy var booksMap: [DBType: [Book]] = {
        DBType.allCases.reduce(into: [DBType: [Book]]()) { map, type in
            map[type] = {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: type.rawValue)
                return (try? context.fetch(request) as? [NSManagedObject]).flatMap { $0.map { bookFrom(obj: $0) }.reversed() } ?? [Book]()
            }()
        }
    }()
    
    func setup() {
        context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    func books(of type: DBType) -> [Book] {
        booksMap[type]!
    }
    
    func insert(book: Book, of type: DBType) {
        lock.lock()
        defer { lock.unlock() }
        booksMap[type]!.insert(book, at: 0)
        
        queue.async { [weak self] in
            guard let self = self else { return }
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: type.rawValue)
            request.predicate = NSPredicate(format: "gid = %d", book.gid)
            let obj = NSEntityDescription.insertNewObject(forEntityName: type.rawValue, into: self.context)
            self.update(obj: obj, with: book)
            self.saveDB()
        }
    }
    
    func remove(book: Book, of type: DBType) {
        lock.lock()
        defer { lock.unlock() }
        booksMap[type]?.removeAll { $0.gid == book.gid }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: type.rawValue)
            request.predicate = NSPredicate(format: "gid = %d", book.gid)
            if let objs = try? self.context.fetch(request) as? [NSManagedObject] {
                for obj in objs { self.context.delete(obj) }
                self.saveDB()
            }
        }
    }
    
    func removeAll(type: DBType) {
        lock.lock()
        defer { lock.unlock() }
        booksMap[type]?.removeAll()
        
        queue.async { [weak self] in
            guard let self = self else { return }
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: type.rawValue)
            if let objs = try? self.context.fetch(request) as? [NSManagedObject] {
                for obj in objs { self.context.delete(obj) }
                self.saveDB()
            }
        }
    }
    
    func contains(gid: Int, of type: DBType) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return booksMap[type]!.contains(where: { $0.gid == gid })
    }
    
    private func saveDB() {
        if context.hasChanges { try? context.save() }
    }
    
    private func bookFrom(obj: NSManagedObject) -> Book {
        Book(gid: obj.value(forKey: "gid") as? Int ?? 0,
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
             torrents: (obj.value(forKey: "torrents") as? String ?? "").data(using: .utf8).flatMap { try? JSONDecoder().decode([Torrent].self, from: $0) } ?? [Torrent]())
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
        obj.setValue((try? JSONEncoder().encode(book.torrents)).flatMap { String(data: $0, encoding: .utf8) } ?? "", forKey: "torrents")
    }
}
