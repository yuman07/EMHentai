//
//  Int+Tools.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/21.
//

import Foundation

extension Int {
    private enum Constant {
        static let oneKB = 1024
        static let oneMB = oneKB * 1024
        static let oneGB = oneMB * 1024
        static let oneTB = oneGB * 1024
    }
    
    var diskSizeFormat: String {
        switch self {
        case ..<Constant.oneKB:
            return "\(self) Byte"
        case Constant.oneKB ..< Constant.oneMB:
            return String(format: "%.2f KB", Double(self) / Double(Constant.oneKB))
        case Constant.oneMB ..< Constant.oneGB:
            return String(format: "%.2f MB", Double(self) / Double(Constant.oneMB))
        case Constant.oneGB ..< Constant.oneTB:
            return String(format: "%.2f GB", Double(self) / Double(Constant.oneGB))
        default:
            return String(format: "%.2f TB", Double(self) / Double(Constant.oneTB))
        }
    }
}
