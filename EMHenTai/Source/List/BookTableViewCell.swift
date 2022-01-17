//
//  BookTableViewCell.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/17.
//

import Foundation
import UIKit
import Kingfisher

class BookTableViewCell: UITableViewCell {
    
    var book: Book?
    
    let thumbImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 13)
        return label
    }()
    
    let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupUI() {
        contentView.addSubview(thumbImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(categoryLabel)
        contentView.addSubview(scoreLabel)
        
        thumbImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8).isActive = true
        thumbImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 8).isActive = true
        thumbImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8).isActive = true
        thumbImageView.widthAnchor.constraint(equalToConstant: 125).isActive = true
        thumbImageView.heightAnchor.constraint(equalToConstant: 125).isActive = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: thumbImageView.topAnchor).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: thumbImageView.rightAnchor, constant: 15).isActive = true
        titleLabel.rightAnchor.constraint(lessThanOrEqualTo: scoreLabel.rightAnchor).isActive = true
        
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5).isActive = true
        categoryLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor).isActive = true
        
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.bottomAnchor.constraint(equalTo: thumbImageView.bottomAnchor).isActive = true
        scoreLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -8).isActive = true
    }
    
    func updateWith(book: Book) {
        self.book = book
        
        thumbImageView.kf.setImage(with: URL(string: book.thumb))
        titleLabel.text = book.title
        categoryLabel.text = book.category
        scoreLabel.text = book.rating
    }
}
