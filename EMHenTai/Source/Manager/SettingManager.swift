//
//  SettingManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/18.
//

import Foundation
import WebKit
import Kingfisher

final class SettingManager {
    static let shared = SettingManager()
    static let LoginStateChangedNotification = NSNotification.Name(rawValue: "EMHenTai.SettingManager.LoginStateChangedNotification")
    
    private var token: NSObjectProtocol?
    
    lazy var isLogin = checkLogin() {
        didSet {
            if isLogin != oldValue {
                NotificationCenter.default.post(name: SettingManager.LoginStateChangedNotification, object: nil)
            }
        }
    }
    
    private init() {
        setupNotification()
    }
    
    deinit {
        token.flatMap { NotificationCenter.default.removeObserver($0) }
    }
    
    private func setupNotification() {
        token = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSHTTPCookieManagerCookiesChanged,
                                                       object: nil,
                                                       queue: .main) { [weak self] _ in
            guard let self else { return }
            self.isLogin = self.checkLogin()
        }
    }
    
    func logout() {
        if let cookies = HTTPCookieStorage.shared.cookies {
            cookies.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
        }
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            cookies.forEach { WKWebsiteDataStore.default().httpCookieStore.delete($0, completionHandler: nil) }
        }
    }
    
    func calculateFileSize() async -> (historySize: Int, downloadSize: Int, otherSize: Int) {
        await withUnsafeContinuation { continuation in
            DispatchQueue.global().async {
                let otherSize = Int((try? KingfisherManager.shared.cache.diskStorage.totalSize()) ?? 0)
                guard let folders = try? FileManager.default.contentsOfDirectory(atPath: Book.downloadFolderPath), !folders.isEmpty else {
                    continuation.resume(returning: (0, 0, otherSize))
                    return
                }
                
                let size = folders.compactMap({ Int($0) }).reduce(into: (0, 0)) {
                    let folderSize = FileManager.default.folderSizeAt(path: Book.downloadFolderPath + "/\($1)")
                    if DBManager.shared.contains(gid: $1, of: .download) { $0.1 += folderSize }
                    else if DBManager.shared.contains(gid: $1, of: .history) { $0.0 += folderSize }
                }
                
                continuation.resume(returning: (size.0, size.1, otherSize))
            }
        }
    }
    
    func clearOtherSize() async {
        await withUnsafeContinuation({ continuation in
            KingfisherManager.shared.cache.clearDiskCache {
                continuation.resume()
            }
        })
    }
    
    private func checkLogin() -> Bool {
        guard let cookies = HTTPCookieStorage.shared.cookies, !cookies.isEmpty else { return false }
        func isValidID(_ id: String) -> Bool { !id.isEmpty && id.lowercased() != "mystery" && id.lowercased() != "null" }
        let currentDate = Date()
        var validFlags = (false, false, false)
        for cookie in cookies {
            guard let expiresDate = cookie.expiresDate, expiresDate > currentDate else { continue }
            if cookie.name == "ipb_member_id" { validFlags.0 = isValidID(cookie.value) }
            if cookie.name == "ipb_pass_hash" { validFlags.1 = isValidID(cookie.value) }
            if cookie.name == "igneous" { validFlags.2 = isValidID(cookie.value) }
            if validFlags == (true, true, true) { return true }
        }
        return false
    }
}
