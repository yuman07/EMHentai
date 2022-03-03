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
        return windows.count == 1 ? windows.first : windows.first(where: { $0.isKeyWindow })
    }
    
    var APPIcon: UIImage? {
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
}
