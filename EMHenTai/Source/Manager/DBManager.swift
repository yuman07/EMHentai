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
    
    let dbChangedSubject = PassthroughSubject<DBType, Never>()
    
    private var booksMap = [DBType: [Book]]()
    private let queue = DispatchQueue(label: "com.DBManager.ConcurrentQueue", attributes: .concurrent)
    private var context: NSManagedObjectContext?
    private init() {}
    
    func setupDB() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            let semaphore = DispatchSemaphore(value: 0)
            let container = NSPersistentContainer(name: "EMDB")
            container.loadPersistentStores { [weak self] _, error in
                guard let self else { semaphore.signal(); return }
                if error == nil { context = container.newBackgroundContext() }
                semaphore.signal()
            }
            semaphore.wait()
            
            guard let context else { return }
            booksMap = DBType.allCases.reduce(into: [DBType: [Book]]()) { map, type in
                map[type] = {
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
            guard let self, !p_contains(gid: book.gid, of: type) else { return }
            
            booksMap[type]?.insert(book, at: 0)
            dbChangedSubject.send(type)
            
            guard let context else { return }
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
            
            booksMap[type]?.removeAll { $0.gid == book.gid }
            dbChangedSubject.send(type)
            
            guard let context else { return }
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
            
            booksMap[type]?.removeAll()
            dbChangedSubject.send(type)
            
            guard let context else { return }
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
        Book(
            gid: obj.value(forKey: "gid") as? Int ?? 0,
            title: obj.value(forKey: "title") as? String,
            titleJpn: obj.value(forKey: "titleJpn") as? String,
            category: obj.value(forKey: "category") as? String,
            thumb: obj.value(forKey: "thumb") as? String,
            fileCount: obj.value(forKey: "fileCount") as? Int ?? 0,
            tags: (obj.value(forKey: "tags") as? [String] ?? []),
            token: obj.value(forKey: "token") as? String,
            rating: obj.value(forKey: "rating") as? String
        )
    }
    
    private static func update(obj: NSManagedObject, with book: Book) {
        obj.setValue(book.gid, forKey: "gid")
        obj.setValue(book.title, forKey: "title")
        obj.setValue(book.titleJpn, forKey: "titleJpn")
        obj.setValue(book.category, forKey: "category")
        obj.setValue(book.thumb, forKey: "thumb")
        obj.setValue(book.fileCount, forKey: "fileCount")
        obj.setValue(book.tags, forKey: "tags")
        obj.setValue(book.token, forKey: "token")
        obj.setValue(book.rating, forKey: "rating")
    }
}
