//
//  LoginViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/19.
//

import Foundation
import UIKit
import WebKit

class LoginViewController: UIViewController {
    private static let loginURL = "https://forums.e-hentai.org/index.php?act=Login&CODE=01"
    
    private let webView = WKWebView()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupData()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(webView)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        webView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }
    
    private func setupData() {
        guard let url = URL(string: LoginViewController.loginURL) else { return }
        webView.configuration.websiteDataStore.httpCookieStore.add(self)
        webView.load(URLRequest(url: url))
    }
}

extension LoginViewController: WKHTTPCookieStoreObserver {
    func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        cookieStore.getAllCookies {
            for cookie in $0 {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
    }
}
