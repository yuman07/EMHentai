//
//  Book.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation

struct Book: Hashable {
    let gid: Int
    let title: String?
    let titleJpn: String?
    let category: String?
    let thumb: String?
    let fileCount: Int
    let tags: [String]
    let token: String?
    let rating: String?
}
