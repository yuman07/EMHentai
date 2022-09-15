//
//  LoginViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/3/5.
//

import Foundation
import UIKit
import WebKit

final class LoginViewController: WebViewController {
    private static let forums = "https://forums.e-hentai.org/index.php?"
    private static let loginURL = URL(string: "\(forums)act=Login")!
    
    private var token: NSObjectProtocol?

    init() {
        super.init(url: LoginViewController.loginURL)
        webView.navigationDelegate = self
        setupNotification()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        token.flatMap { NotificationCenter.default.removeObserver($0) }
    }
    
    private func setupNotification() {
        token = NotificationCenter.default.addObserver(forName: SettingManager.LoginStateChangedNotification,
                                                       object: nil,
                                                       queue: .main) { [weak self] _ in
            guard let self, SettingManager.shared.isLogin else { return }
            let vc = UIAlertController(title: "提示", message: "登录成功", preferredStyle: .alert)
            vc.addAction(UIAlertAction(title: "好的", style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(vc, animated: true, completion: nil)
        }
    }
}

extension LoginViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            cookies.forEach { HTTPCookieStorage.shared.setCookie($0) }
        }
        if (webView.url?.absoluteString ?? "") == Self.forums {
            webView.load(URLRequest(url: URL(string: SearchInfo.Source.ExHentai.rawValue)!))
        }
    }
}
