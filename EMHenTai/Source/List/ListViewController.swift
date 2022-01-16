//
//  ListViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import UIKit

enum ListStyle {
    case Home
    case History
    case Download
}

class ListViewController: UIViewController {
    
    let style: ListStyle
    
    init(style: ListStyle) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.style = .Home
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavBar()
        setupData()
    }
    
    private func setupView() {
        view.backgroundColor = .white
    }
    
    private func setupNavBar() {
        switch style {
        case .Home:
            navigationItem.title = "主页"
        case .History:
            navigationItem.title = "历史"
        case .Download:
            navigationItem.title = "下载"
        }
    }
    
    private func setupData() {
        refreshDataWith(searchInfo: SearchInfo())
    }
    
    func refreshDataWith(searchInfo: SearchInfo) {
        SearchManager.shared.searchWith(info: searchInfo) { books in
            print(books)
            if books.count > 0 {
                print("请求成功")
            } else {
                print("请求失败")
            }
        }
    }
}
