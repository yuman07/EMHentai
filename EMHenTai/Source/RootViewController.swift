//
//  RootViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import UIKit

final class RootViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        viewControllers = [
            {
                let vc = UINavigationController(rootViewController: BookListViewController(type: .Home))
                vc.tabBarItem.title = "主页"
                vc.tabBarItem.image = UIImage(systemName: "house", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14))
                return vc
            }(),
            {
                let vc = UINavigationController(rootViewController: BookListViewController(type: .History))
                vc.tabBarItem.title = "历史"
                vc.tabBarItem.image = UIImage(systemName: "clock", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14))
                return vc
            }(),
            {
                let vc = UINavigationController(rootViewController: BookListViewController(type: .Download))
                vc.tabBarItem.title = "下载"
                vc.tabBarItem.image = UIImage(systemName: "tray.and.arrow.down.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14))
                return vc
            }(),
            {
                let vc = UINavigationController(rootViewController: SettingViewController())
                vc.tabBarItem.title = "设置"
                vc.tabBarItem.image = UIImage(systemName: "gear", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14))
                return vc
            }(),
        ]
    }
}
