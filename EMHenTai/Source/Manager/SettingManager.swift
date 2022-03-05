//
//  SettingManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/18.
//

import Foundation
import WebKit

final class SettingManager {
    static let shared = SettingManager()
    static let LoginStateChangedNotification = NSNotification.Name(rawValue: "EMHenTai.SettingManager.LoginStateChangedNotification")
    
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
        if let cookies = HTTPCookieStorage.shared.cookies {
            cookies.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
        }
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            cookies.forEach { WKWebsiteDataStore.default().httpCookieStore.delete($0, completionHandler: nil) }
        }
    }
    
    func calculateFilesSize(completion: @escaping ((downloadSize: Int, historySize: Int)) -> Void) {
        guard let folders = try? FileManager.default.contentsOfDirectory(atPath: Book.downloadFolderPath), !folders.isEmpty else {
            DispatchQueue.main.async { completion((0, 0)) }
            return
        }
        
        DispatchQueue.global().async {
            let size = folders.reduce(into: (0, 0)) {
                let gid = Int($1) ?? 0
                if DBManager.shared.contains(gid: gid, of: .download) {
                    $0.0 += FileManager.default.folderSizeAt(path: Book.downloadFolderPath + "/\($1)")
                } else if DBManager.shared.contains(gid: gid, of: .history) {
                    $0.1 += FileManager.default.folderSizeAt(path: Book.downloadFolderPath + "/\($1)")
                }
            }
            DispatchQueue.main.async { completion(size) }
        }
    }
    
    private func checkLogin() -> Bool {
        guard let cookies = HTTPCookieStorage.shared.cookies else { return false }
        func isVaildID(_ id: String) -> Bool { !id.isEmpty && id.lowercased() != "mystery" && id.lowercased() != "null" }
        var memberIDVaild = false
        var passHashVaild = false
        var igneousVaild = false
        for cookie in cookies {
            guard let expiresDate = cookie.expiresDate, expiresDate > Date() && !cookie.value.isEmpty else { continue }
            if cookie.name == "ipb_member_id" { memberIDVaild = isVaildID(cookie.value) }
            if cookie.name == "ipb_pass_hash" { passHashVaild = isVaildID(cookie.value) }
            if cookie.name == "igneous" { igneousVaild = isVaildID(cookie.value) }
        }
        return memberIDVaild && passHashVaild && igneousVaild
    }
}
