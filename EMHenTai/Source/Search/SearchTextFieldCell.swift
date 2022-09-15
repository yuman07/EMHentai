//
//  SearchTextFieldCell.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/18.
//

import Foundation
import UIKit

final class SearchTextFieldCell: UITableViewCell {
    
    var textChangedAction: ((String) -> Void)?
    
    lazy var searchTextField = {
        let view = UITextField()
        view.delegate = self
        view.layer.borderWidth = 0.5
        view.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0)
        view.layer.borderColor = UIColor.gray.cgColor
        view.layer.cornerRadius = 5
        view.font = .systemFont(ofSize: 14)
        view.returnKeyType = .done
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupAction()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(searchTextField)
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.leftAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leftAnchor, constant: 15).isActive = true
        searchTextField.rightAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.rightAnchor, constant: -15).isActive = true
        searchTextField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        searchTextField.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
    
    private func setupAction() {
        searchTextField.addTarget(self, action: #selector(textFieldDidChanged), for: .editingChanged)
    }
    
    @objc
    private func textFieldDidChanged() {
        textChangedAction?(searchTextField.text ?? "")
    }
}

extension SearchTextFieldCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField.resignFirstResponder()
        return true
    }
}
