//
//  String+Tools.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/17.
//

import Foundation

extension String {
    private func allIndicesOf(string: String) -> [Int] {
        var indices = [Int]()
        var start = startIndex
        while start < endIndex, let range = range(of: string, range: start..<endIndex), !range.isEmpty {
            indices.append(distance(from: startIndex, to: range.lowerBound))
            start = range.upperBound
        }
        return indices
    }
    
    func allSubStringOf(target: String, endCharater: Character, count: Int = 1) -> [String] {
        allIndicesOf(string: target).map {
            guard case let start = index(startIndex, offsetBy: $0 + target.count), start < endIndex else { return "" }
            var end = index(after: start)
            var meet = 0
            while end < endIndex && meet < count  {
                end = index(after: end)
                if self[end] == endCharater { meet += 1 }
            }
            return "\(self[start..<end])"
        }
    }
}
