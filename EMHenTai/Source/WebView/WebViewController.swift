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
    private let url: URL
    private let needSyncCookieToApp: Bool
    private let shareItem: (shareTitle: String?, shareImage: UIImage?)?
    
    init(url: URL, needSyncCookieToApp: Bool = false, shareItem: (shareTitle: String?, shareImage: UIImage?)? = nil) {
        self.url = url
        self.needSyncCookieToApp = needSyncCookieToApp
        self.shareItem = shareItem
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
        
        if shareItem != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareAction))
        }
    }
    
    private func setupData() {
        webView.load(URLRequest(url: url))
    }
    
    @objc
    func shareAction() {
        guard let shareItem = shareItem else { return }
        let title = shareItem.shareTitle ?? self.title ?? self.url.absoluteString
        let image = shareItem.shareImage ?? UIApplication.shared.APPIcon ?? UIImage()
        let vc = UIActivityViewController(activityItems: [title, image, self.url], applicationActivities: nil)
        vc.completionWithItemsHandler = { _, _, _, _ in
            vc.dismiss(animated: true, completion: nil)
        }
        present(vc, animated: true, completion: nil)
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
