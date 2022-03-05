//
//  UIImage+Tools.swift
//  EMHenTai
//
//  Created by yuman on 2022/3/5.
//

import Foundation
import UIKit

extension UIImage {
    enum SFSymbol: String {
        case home = "house"
        case history = "clock"
        case download = "tray.and.arrow.down.fill"
        case setting = "gear"
        case trash
    }
    
    convenience init?(symbol: SFSymbol, size: CGFloat = 14) {
        self.init(systemName: symbol.rawValue, withConfiguration: UIImage.SymbolConfiguration(pointSize: size))
    }
}
