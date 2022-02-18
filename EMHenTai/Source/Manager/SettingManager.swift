//
//  SettingManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/18.
//

import Foundation

class SettingManager {
    static let shared = SettingManager()
    static let LoginStateChangedNotification = NSNotification.Name(rawValue: "EMHenTai.SettingManager.LoginStateChangedNotification")
    
    let loginURL = "https://forums.e-hentai.org/index.php?act=Login"
    
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
    
    private func setupNotification() {
        var token: NSObjectProtocol?
        token = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSHTTPCookieManagerCookiesChanged,
                                                       object: nil,
                                                       queue: .main) { [weak self] _ in
            guard let self = self else { NotificationCenter.default.removeObserver(token!); return }
            self.isLogin = self.checkLogin()
        }
    }
    
    func logout() {
        guard let cookies = HTTPCookieStorage.shared.cookies else { return }
        cookies.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
    }
    
    func calculateFilesSize(completion: @escaping ((downloadSize: Int, historySize: Int)) -> Void) {
        guard let folders = try? FileManager.default.contentsOfDirectory(atPath: Book.downloadFolderPath), !folders.isEmpty else {
            DispatchQueue.main.async { completion((0, 0)) }
            return
        }
        
        DispatchQueue.global().async {
            let size = folders.reduce(into: (0, 0)) {
                let gid = Int($1) ?? 0
                if DBManager.shared.booksMap[.download]!.contains(where: { $0.gid == gid }) {
                    $0.0 += FileManager.default.folderSizeAt(path: Book.downloadFolderPath + "/\($1)")
                } else if DBManager.shared.booksMap[.history]!.contains(where: { $0.gid == gid }) {
                    $0.1 += FileManager.default.folderSizeAt(path: Book.downloadFolderPath + "/\($1)")
                }
            }
            DispatchQueue.main.async { completion(size) }
        }
    }
    
    private func checkLogin() -> Bool {
        guard let cookies = HTTPCookieStorage.shared.cookies else { return false }
        var igneous: String?
        var memberID: String?
        var passHash: String?
        for cookie in cookies {
            guard let expiresDate = cookie.expiresDate, expiresDate > Date() && !cookie.value.isEmpty && cookie.value.lowercased() != "null" else { continue }
            if cookie.name == "igneous" && cookie.value != "mystery" {
                igneous = cookie.value
            }
            if cookie.name ==  "ipb_member_id" {
                memberID = cookie.value
            }
            if cookie.name == "ipb_pass_hash" {
                passHash = cookie.value
            }
        }
        return igneous != nil && memberID != nil && passHash != nil
    }
}
