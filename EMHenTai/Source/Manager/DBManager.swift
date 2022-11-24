//
//  DBManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/20.
//

import Combine
import CoreData

final class DBManager {
    enum DBType: String, CaseIterable {
        case history = "HistoryBook"
        case download = "DownloadBook"
    }
    
    static let shared = DBManager()
    
    let DBChangedSubject = PassthroughSubject<DBType, Never>()
    
    private var booksMap = [DBType: [Book]]()
    private let queue = DispatchQueue(label: "com.DBManager.ConcurrentQueue", attributes: .concurrent)
    private let semaphore = DispatchSemaphore(value: 0)
    private var context: NSManagedObjectContext?
    private init() {}
    
    func setupDB() {
        let container = NSPersistentContainer(name: "EMDB")
        
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            container.loadPersistentStores { [weak self] _, error in
                guard let self else { return }
                if error == nil { self.context = container.newBackgroundContext() }
                self.semaphore.signal()
            }
            self.semaphore.wait()
        }
        
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            self.booksMap = DBType.allCases.reduce(into: [DBType: [Book]]()) { map, type in
                map[type] = {
                    guard let context = self.context else { return [] }
                    let request = NSFetchRequest<NSFetchRequestResult>(entityName: type.rawValue)
                    return (try? context.fetch(request) as? [NSManagedObject]).flatMap { $0.map { Self.bookFrom(obj: $0) }.reversed() } ?? []
                }()
            }
        }
    }
    
    func books(of type: DBType) -> [Book] {
        queue.sync { booksMap[type] ?? [] }
    }
    
    func contains(gid: Int, of type: DBType) -> Bool {
        queue.sync { p_contains(gid: gid, of: type) }
    }
    
    private func p_contains(gid: Int, of type: DBType) -> Bool {
        booksMap[type]?.contains(where: { $0.gid == gid }) ?? false
    }
    
    func insert(book: Book, of type: DBType) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self, !self.p_contains(gid: book.gid, of: type) else { return }
            
            self.booksMap[type]?.insert(book, at: 0)
            self.DBChangedSubject.send(type)
            
            guard let context = self.context else { return }
            context.perform {
                let obj = NSEntityDescription.insertNewObject(forEntityName: type.rawValue, into: context)
                Self.update(obj: obj, with: book)
                try? context.save()
            }
        }
    }
    
    func remove(book: Book, of type: DBType) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            
            self.booksMap[type]?.removeAll { $0.gid == book.gid }
            self.DBChangedSubject.send(type)
            
            guard let context = self.context else { return }
            context.perform {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: type.rawValue)
                request.predicate = NSPredicate(format: "gid = %d", book.gid)
                let delRequest = NSBatchDeleteRequest(fetchRequest: request)
                if (try? context.execute(delRequest)) != nil {
                    try? context.save()
                }
            }
        }
    }
    
    func removeAll(type: DBType) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            
            self.booksMap[type]?.removeAll()
            self.DBChangedSubject.send(type)
            
            guard let context = self.context else { return }
            context.perform {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: type.rawValue)
                let delRequest = NSBatchDeleteRequest(fetchRequest: request)
                if (try? context.execute(delRequest)) != nil {
                    try? context.save()
                }
            }
        }
    }
    
    private static func bookFrom(obj: NSManagedObject) -> Book {
        Book(gid: obj.value(forKey: "gid") as? Int ?? 0,
             title: obj.value(forKey: "title") as? String ?? "",
             title_jpn: obj.value(forKey: "title_jpn") as? String ?? "",
             category: obj.value(forKey: "category") as? String ?? "",
             thumb: obj.value(forKey: "thumb") as? String ?? "",
             uploader: obj.value(forKey: "uploader") as? String ?? "",
             filecount: obj.value(forKey: "filecount") as? String ?? "",
             filesize: obj.value(forKey: "filesize") as? Int ?? 0,
             tags: (obj.value(forKey: "tags") as? [String] ?? []),
             token: obj.value(forKey: "token") as? String ?? "",
             rating: obj.value(forKey: "rating") as? String ?? "",
             archiver_key: obj.value(forKey: "archiver_key") as? String ?? "",
             posted: obj.value(forKey: "posted") as? String ?? "",
             expunged: obj.value(forKey: "expunged") as? Bool ?? false,
             torrentcount: obj.value(forKey: "torrentcount") as? String ?? "",
             torrents: (obj.value(forKey: "torrents") as? [[String: String]] ?? []))
    }
    
    private static func update(obj: NSManagedObject, with book: Book) {
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
        obj.setValue(book.torrents, forKey: "torrents")
    }
}
