//
//  AppDelegate.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Kingfisher
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private func setupKingfisher() {
        let c = KingfisherManager.shared.downloader.sessionConfiguration
        c.httpCookieStorage = HTTPCookieStorage.shared
        KingfisherManager.shared.downloader.sessionConfiguration = c
    }
    
    private func setupDB() {
        DBManager.shared.setupDB()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        setupKingfisher()
        setupDB()
        return true
    }
}
