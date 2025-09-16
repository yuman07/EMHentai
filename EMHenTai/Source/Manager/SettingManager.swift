//
//  SettingManager.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/18.
//

import Combine
import Kingfisher
import WebKit

final class SettingManager {
    static let shared = SettingManager()
    
    var isAIDisabled: Bool {
        get { UserDefaults.standard.bool(forKey: "SettingManager_isAIDisabled") }
        set { UserDefaults.standard.set(newValue, forKey: "SettingManager_isAIDisabled") }
    }
    var isGoreDisabled: Bool {
        get { UserDefaults.standard.bool(forKey: "SettingManager_isGoreDisabled") }
        set { UserDefaults.standard.set(newValue, forKey: "SettingManager_isGoreDisabled") }
    }
    
    private(set) lazy var isLoginSubject = CurrentValueSubject<Bool, Never>(checkLogin())
    private var cancelBag = Set<AnyCancellable>()
    
    private init() {
        setupCombine()
    }
    
    private func setupCombine() {
        NotificationCenter.default
            .publisher(for: .NSHTTPCookieManagerCookiesChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                if case let newValue = checkLogin(), isLoginSubject.value != newValue {
                    isLoginSubject.send(newValue)
                }
            }
            .store(in: &cancelBag)
    }
    
    func loginWith(cookie: String) {
        guard case let coms = cookie.split(separator: "x"), coms.count == 2, coms[0].count > 32, coms[1].count > 0 else { return }
        let passHashs = createCookies(name: "ipb_pass_hash", value: "\(coms[0].prefix(32))")
        let memberIDs = createCookies(name: "ipb_member_id", value: "\(coms[0].suffix(coms[0].count - 32))")
        let igneouss = createCookies(name: "igneous", value: "\(coms[1])")
        
        [passHashs, memberIDs, igneouss]
            .flatMap(\.self)
            .forEach { HTTPCookieStorage.shared.setCookie($0) }
    }
    
    func logout() {
        if let cookies = HTTPCookieStorage.shared.cookies {
            cookies.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
        }
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            cookies.forEach { WKWebsiteDataStore.default().httpCookieStore.delete($0) }
        }
    }
    
    func calculateUsedDiskSize() async -> (historySize: Int, downloadSize: Int, otherSize: Int) {
        var otherSize = Int((try? KingfisherManager.shared.cache.diskStorage.totalSize()) ?? 0)
        guard let folders = try? FileManager.default.contentsOfDirectory(atPath: Book.downloadFolderPath), !folders.isEmpty else {
            return (0, 0, otherSize)
        }
        
        let size = folders.compactMap({ Int($0) }).reduce(into: (0, 0)) {
            let folderSize = FileManager.default.folderSizeAt(path: Book.downloadFolderPath + "/\($1)")
            if DBManager.shared.contains(gid: $1, of: .download) { $0.1 += folderSize }
            else if DBManager.shared.contains(gid: $1, of: .history) { $0.0 += folderSize }
            else { otherSize += folderSize }
        }
        
        return (size.0, size.1, otherSize)
    }
    
    func clearOtherData() async {
        await KingfisherManager.shared.cache.clearDiskCache()
        guard let folders = try? FileManager.default.contentsOfDirectory(atPath: Book.downloadFolderPath), !folders.isEmpty else {
            return
        }
        folders.compactMap({ Int($0) }).forEach {
            let path = Book.downloadFolderPath + "/\($0)"
            if !DBManager.shared.contains(gid: $0, of: .download) && !DBManager.shared.contains(gid: $0, of: .history) {
                try? FileManager.default.removeItem(atPath: path)
            }
        }
    }
    
    private func createCookies(name: String, value: String) -> [HTTPCookie] {
        [".exhentai.org", ".e-hentai.org"].compactMap {
            HTTPCookie(properties: [.domain: $0, .name: name, .value: value, .path: "/", .expires: Date(timeInterval: 157784760, since: Date())])
        }
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
