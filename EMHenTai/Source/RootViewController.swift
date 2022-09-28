//
//  RootViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import UIKit

final class RootViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        viewControllers = [
            {
                let vc = UINavigationController(rootViewController: BookcaseViewController(type: .home))
                vc.tabBarItem.title = "主页"
                vc.tabBarItem.image = UIImage(symbol: .home)
                return vc
            }(),
            {
                let vc = UINavigationController(rootViewController: BookcaseViewController(type: .history))
                vc.tabBarItem.title = "历史"
                vc.tabBarItem.image = UIImage(symbol: .history)
                return vc
            }(),
            {
                let vc = UINavigationController(rootViewController: BookcaseViewController(type: .download))
                vc.tabBarItem.title = "下载"
                vc.tabBarItem.image = UIImage(symbol: .download)
                return vc
            }(),
            {
                let vc = UINavigationController(rootViewController: SettingViewController())
                vc.tabBarItem.title = "设置"
                vc.tabBarItem.image = UIImage(symbol: .setting)
                return vc
            }(),
        ]
    }
}
