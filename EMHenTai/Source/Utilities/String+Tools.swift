//
//  String+Tools.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/17.
//

import Foundation

extension String {
    func allIndicesOf(string: String) -> [Int] {
        var indices = [Int]()
        var searchStartIndex = self.startIndex
        while searchStartIndex < self.endIndex, let range = self.range(of: string, range: searchStartIndex..<self.endIndex), !range.isEmpty {
            let index = distance(from: self.startIndex, to: range.lowerBound)
            indices.append(index)
            searchStartIndex = range.upperBound
        }
        return indices
    }
}
