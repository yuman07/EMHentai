//
//  DBManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/20.
//

import CoreData

protocol DBManagerDelegate: AnyObject {
    func DBChanged(of type: DBManager.DBType)
}

final class DBManager {
    enum DBType: String, CaseIterable {
        case history = "HistoryBook"
        case download = "DownloadBook"
    }
    
    static let shared = DBManager()
    
    weak var delegate: DBManagerDelegate?
    
    private var context: NSManagedObjectContext?
    private var booksMap = [DBType: [Book]]()
    private let queue = DispatchQueue(label: "com.DBManager.ConcurrentQueue", attributes: .concurrent)
    
    private init() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            
            let container = NSPersistentContainer(name: "EMDB")
            container.loadPersistentStores { _, error in
                if error == nil { self.context = container.newBackgroundContext() }
            }
            
            self.booksMap = DBType.allCases.reduce(into: [DBType: [Book]]()) { map, type in
                map[type] = {
                    guard let context = self.context else { return [Book]() }
                    let request = NSFetchRequest<NSFetchRequestResult>(entityName: type.rawValue)
                    return (try? context.fetch(request) as? [NSManagedObject]).flatMap { $0.map { Self.bookFrom(obj: $0) }.reversed() } ?? [Book]()
                }()
            }
        }
    }
    
    func books(of type: DBType) -> [Book] {
        queue.sync { booksMap[type] ?? [Book]() }
    }
    
    func contains(gid: Int, of type: DBType) -> Bool {
        queue.sync { booksMap[type]?.contains(where: { $0.gid == gid }) ?? false }
    }
    
    func insert(book: Book, of type: DBType) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            
            self.booksMap[type]?.insert(book, at: 0)
            
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.DBChanged(of: type)
            }
            
            guard let context = self.context else { return }
            context.perform {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: type.rawValue)
                request.predicate = NSPredicate(format: "gid = %d", book.gid)
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
            
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.DBChanged(of: type)
            }
            
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
            
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.DBChanged(of: type)
            }
            
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
             tags: (obj.value(forKey: "tags") as? String ?? "").components(separatedBy: ","),
             token: obj.value(forKey: "token") as? String ?? "",
             rating: obj.value(forKey: "rating") as? String ?? "",
             archiver_key: obj.value(forKey: "archiver_key") as? String ?? "",
             posted: obj.value(forKey: "posted") as? String ?? "",
             expunged: obj.value(forKey: "expunged") as? Bool ?? false,
             torrentcount: obj.value(forKey: "torrentcount") as? String ?? "",
             torrents: (obj.value(forKey: "torrents") as? String ?? "").data(using: .utf8).flatMap { try? JSONDecoder().decode([Torrent].self, from: $0) } ?? [Torrent]())
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
        obj.setValue((try? JSONEncoder().encode(book.torrents)).flatMap { String(data: $0, encoding: .utf8) } ?? "", forKey: "torrents")
    }
}
