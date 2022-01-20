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
        var searchStartIndex = startIndex
        while searchStartIndex < endIndex, let range = range(of: string, range: searchStartIndex..<endIndex), !range.isEmpty {
            indices.append(distance(from: startIndex, to: range.lowerBound))
            searchStartIndex = range.upperBound
        }
        return indices
    }
}
