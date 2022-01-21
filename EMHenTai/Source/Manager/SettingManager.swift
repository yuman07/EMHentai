//
//  SettingManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/18.
//

import Foundation

enum UserLanguage: String, CaseIterable {
    case english = "英文(English)"
    case chineseSimplified = "简体中文(Simplified Chinese)"
}

class SettingManager {
    static let shared = SettingManager()
    static let LoginStateChangedNotification = NSNotification.Name(rawValue: "EMHenTai.SettingManager.LoginStateChangedNotification")
    
    private init() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSHTTPCookieManagerCookiesChanged,
                                               object: nil,
                                               queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.isLogin = self.checkLogin()
        }
    }
    
    lazy var isLogin = checkLogin() {
        didSet {
            if isLogin != oldValue {
                NotificationCenter.default.post(name: SettingManager.LoginStateChangedNotification, object: nil)
            }
        }
    }
    
    var currentLanguage: UserLanguage {
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "SettingManager_currentLanguage") }
        get {
            let value = (UserDefaults.standard.object(forKey: "SettingManager_currentLanguage") as? String) ?? ""
            return UserLanguage(rawValue: value) ?? UserLanguage.chineseSimplified
        }
    }
    
    func logout() {
        guard let cookies = HTTPCookieStorage.shared.cookies else { return }
        for cookie in cookies {
            if cookie.name == "ipb_pass_hash" {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
    }
    
    func calculateFilesSize(completion: @escaping ((downloadSize: Int, historySize: Int)) -> Void) {
        guard let folders = try? FileManager.default.contentsOfDirectory(atPath: Book.downloadFolderPath), !folders.isEmpty else {
            DispatchQueue.main.async {
                completion((0, 0))
            }
            return
        }
        
        DispatchQueue.global().async {
            var downloadSize = 0
            var historySize = 0
            for folder in folders {
                let gid = Int(folder) ?? 0
                if !DBManager.shared.downloadBooks.filter({ $0.gid == gid }).isEmpty {
                    downloadSize += FileManager.default.folderSizeAt(path: Book.downloadFolderPath + "/\(folder)")
                } else if !DBManager.shared.historyBooks.filter({ $0.gid == gid }).isEmpty {
                    historySize += FileManager.default.folderSizeAt(path: Book.downloadFolderPath + "/\(folder)")
                }
            }
            DispatchQueue.main.async {
                completion((downloadSize, historySize))
            }
        }
    }
    
    private func checkLogin() -> Bool {
        guard let cookies = HTTPCookieStorage.shared.cookies else { return false }
        for cookie in cookies {
            if let expiresDate = cookie.expiresDate, Date() < expiresDate, cookie.name == "ipb_pass_hash" {
                return true
            }
        }
        return false
    }
}
