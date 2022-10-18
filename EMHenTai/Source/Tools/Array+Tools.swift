//
//  Array+Tools.swift
//  EMHenTai
//
//  Created by yuman on 2022/9/16.
//

import Foundation

extension Array where Element: Hashable {
    func unique() -> [Element] {
        guard count > 1 else { return self }
        var set = Set<Element>(minimumCapacity: count)
        return filter { set.insert($0).inserted }
    }
}
