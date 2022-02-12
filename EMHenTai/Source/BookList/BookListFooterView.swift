//
//  BookListFooterView.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/19.
//

import Foundation
import UIKit

class BookListFooterView: UIView {
    enum HintType: String {
        case empty = " "
        case noData = "没有数据"
        case noMoreData = "没有更多数据了"
        case netError = "网络错误：请检查网络连接或VPN设置"
    }
    
    var hint = BookListFooterView.HintType.empty {
        didSet {
            self.label.text = hint.rawValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let label: UILabel = {
        let label = UILabel()
        label.text = BookListFooterView.HintType.empty.rawValue
        label.font = UIFont.systemFont(ofSize: 14)
        label.sizeToFit()
        return label
    }()
    
    private func setupUI() {
        frame = CGRect(x: 0, y: 0, width: 0, height: label.bounds.size.height + 20)
        addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
}
