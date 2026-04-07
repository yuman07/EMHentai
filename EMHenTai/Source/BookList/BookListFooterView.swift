//
//  BookListFooterView.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/19.
//

import UIKit

final class BookListFooterView: UIView {
    enum HintType {
        case empty
        case loading
        case noData
        case noMoreData
        case netError
        case ipError

        var title: String {
            switch self {
            case .empty: return " "
            case .loading: return "footer.loading".localized
            case .noData: return "footer.no_data".localized
            case .noMoreData: return "footer.no_more".localized
            case .netError: return "footer.net_error".localized
            case .ipError: return "footer.ip_error".localized
            }
        }
    }

    var hint = HintType.empty {
        didSet {
            label.text = hint.title
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let label = {
        let label = UILabel()
        label.text = HintType.empty.title
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private func setupUI() {
        frame = CGRect(x: 0, y: 0, width: 0, height: ceil(label.font.lineHeight) + 20)
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}
