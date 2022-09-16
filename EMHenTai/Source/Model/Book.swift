//
//  Book.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation

struct Book: Codable, Hashable {
    let gid: Int
    let title: String
    let title_jpn: String
    let category: String
    let thumb: String
    let uploader: String
    let filecount: String
    let filesize: Int
    let tags: [String]
    let token: String
    let rating: String
    let archiver_key: String
    let posted: String
    let expunged: Bool
    let torrentcount: String
    let torrents: [Torrent]
}

struct Torrent: Codable, Hashable {
    let hash: String
    let added: String
    let name: String
    let tsize: String
    let fsize: String
}
