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
        super.init()
    }
    
    required init?(coder: NSCoder) {
        self.style = .Home
        super.init(coder: coder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.style = .Home
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavBar()
    }
    
    func setupNavBar() {
        switch style {
        case .Home:
            navigationItem.title = "主页"
        case .History:
            navigationItem.title = "历史"
        case .Download:
            navigationItem.title = "下载"
        }
    }
    
    func setupView() {
        view.backgroundColor = .white
        
        SearchManager.shared.searchWith(info: SearchInfo(), pageIndex: 0) { books in
            print(books)
        }
    }
}
