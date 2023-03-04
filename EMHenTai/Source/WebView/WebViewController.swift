//
//  WebViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/2/18.
//

import WebKit

class WebViewController: UIViewController {
    private let url: URL
    private let shareItem: (shareTitle: String?, shareImage: UIImage?)?
    
    let webView = {
        let view = WKWebView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    init(url: URL, shareItem: (shareTitle: String?, shareImage: UIImage?)? = nil) {
        self.url = url
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
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        if shareItem != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareAction))
        }
    }
    
    private func setupData() {
        webView.load(URLRequest(url: url))
    }
    
    @objc
    private func shareAction() {
        guard let shareItem else { return }
        let title = shareItem.shareTitle ?? title ?? url.absoluteString
        let image = shareItem.shareImage ?? UIApplication.shared.APPIcon ?? UIImage()
        let vc = UIActivityViewController(activityItems: [title, image, url], applicationActivities: nil)
        vc.completionWithItemsHandler = { [weak vc] _, _, _, _ in
            vc?.dismiss(animated: true)
        }
        present(vc, animated: true)
    }
}
