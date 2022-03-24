//
//  AppDelegate.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import UIKit
import CoreData
import Kingfisher

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "EMDB")
        container.loadPersistentStores { _, _ in }
        return container
    }()
    
    private func setupDB() {
        DBManager.shared.setup()
    }
    
    private func setupKingfisher() {
        let c = KingfisherManager.shared.downloader.sessionConfiguration
        c.httpCookieStorage = HTTPCookieStorage.shared
        KingfisherManager.shared.downloader.sessionConfiguration = c
    }
    
    private func setupUI() {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = RootViewController()
        window?.makeKeyAndVisible()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        setupDB()
        setupKingfisher()
        setupUI()
        return true
    }
}

