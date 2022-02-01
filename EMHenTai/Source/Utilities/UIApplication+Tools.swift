//
//  UIApplication+Tools.swift
//  EMHenTai
//
//  Created by yuman on 2022/2/1.
//

import Foundation
import UIKit

extension UIApplication {
    var keyWindow: UIWindow? {
        let windows = connectedScenes.compactMap{ $0 as? UIWindowScene }.flatMap{ $0.windows }
        if windows.count == 1 { return windows.first }
        return windows.first(where: { $0.isKeyWindow })
    }
}
