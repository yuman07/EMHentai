//
//  FileManager+Tools.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/21.
//

import Foundation

extension FileManager {
    func folderSizeAt(path: String) -> Int {
        guard let contents = try? FileManager.default.subpathsOfDirectory(atPath: path), !contents.isEmpty else { return 0 }
        return contents.reduce(into: 0) {
            if let fileSize = (try? FileManager.default.attributesOfItem(atPath: path + "/\($1)"))?[.size] as? Int {
                $0 += fileSize
            }
        }
    }
}
