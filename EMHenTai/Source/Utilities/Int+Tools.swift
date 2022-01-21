//
//  Int+Tools.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/21.
//

import Foundation

extension Int {
    var diskSizeFormat: String {
        let oneKB = 1024
        let oneMB = oneKB * 1024
        let oneGB = oneMB * 1024
        let oneTB = oneGB * 1024
        switch self {
        case ..<oneKB:
            return "\(self) Byte"
        case oneKB..<oneMB:
            return String(format: "%.2f KB", Double(self) / Double(oneKB))
        case oneMB..<oneGB:
            return String(format: "%.2f MB", Double(self) / Double(oneMB))
        case oneGB..<oneTB:
            return String(format: "%.2f GB", Double(self) / Double(oneGB))
        default:
            return String(format: "%.2f TB", Double(self) / Double(oneTB))
        }
    }
}
