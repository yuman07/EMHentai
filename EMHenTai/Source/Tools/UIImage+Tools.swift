//
//  UIImage+Tools.swift
//  EMHenTai
//
//  Created by yuman on 2022/3/5.
//

import UIKit

extension UIImage {
    enum SFSymbol: String {
        case home = "house"
        case history = "clock"
        case download = "tray.and.arrow.down.fill"
        case setting = "gear"
        case trash
        case jump = "arrow.uturn.forward"
    }
    
    convenience init?(symbol: SFSymbol, size: CGFloat = 14) {
        self.init(systemName: symbol.rawValue, withConfiguration: UIImage.SymbolConfiguration(pointSize: size))
    }
    
    convenience init?(filePath: String) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else { return nil }
        self.init(data: data)
    }
}
