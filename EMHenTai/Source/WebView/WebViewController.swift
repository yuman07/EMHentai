//
//  WebViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/2/18.
//

import Foundation
import UIKit
import WebKit

class WebViewController: UIViewController {
    private let webView = WKWebView()
    
    let url: URL
    let needSyncCookieToApp: Bool
    
    init(url: URL, needSyncCookieToApp: Bool = false) {
        self.url = url
        self.needSyncCookieToApp = needSyncCookieToApp
        super.init(nibName: nil, bundle: nil)
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
        
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        webView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    private func setupData() {
        webView.load(URLRequest(url: url))
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard needSyncCookieToApp else { return }
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            cookies.forEach { HTTPCookieStorage.shared.setCookie($0) }
        }
    }
}
