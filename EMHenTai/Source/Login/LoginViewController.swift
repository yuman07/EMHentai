//
//  LoginViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/3/5.
//

import WebKit

final class LoginViewController: WebViewController {
    private static let forums = "https://forums.e-hentai.org/index.php?"
    private static let loginURL = URL(string: "\(forums)act=Login")!

    init() {
        super.init(url: LoginViewController.loginURL)
        webView.navigationDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LoginViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            cookies.forEach { HTTPCookieStorage.shared.setCookie($0) }
        }
        if webView.url?.absoluteString == Self.forums {
            webView.load(URLRequest(url: URL(string: SearchInfo.Source.ExHentai.rawValue)!))
        }
    }
}
