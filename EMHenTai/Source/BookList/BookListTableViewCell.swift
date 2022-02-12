//
//  BookListTableViewCell.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/17.
//

import Foundation
import UIKit

class BookListTableViewCell: UITableViewCell {
    
    var book: Book?
    
    var longPressBlock: (() -> Void)?
    
    private let thumbImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 13)
        return label
    }()
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    private let progressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    private let fileCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupGesture()
        setupNoticication()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(thumbImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(categoryLabel)
        contentView.addSubview(progressLabel)
        contentView.addSubview(scoreLabel)
        contentView.addSubview(fileCountLabel)
        
        thumbImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8).isActive = true
        thumbImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 8).isActive = true
        thumbImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8).isActive = true
        thumbImageView.widthAnchor.constraint(equalToConstant: 125).isActive = true
        let constraint = thumbImageView.heightAnchor.constraint(equalToConstant: 125)
        constraint.priority = .defaultHigh
        constraint.isActive = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: thumbImageView.topAnchor).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: thumbImageView.rightAnchor, constant: 8).isActive = true
        titleLabel.rightAnchor.constraint(lessThanOrEqualTo: scoreLabel.rightAnchor).isActive = true
        
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8).isActive = true
        categoryLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor).isActive = true
        
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.bottomAnchor.constraint(equalTo: fileCountLabel.bottomAnchor).isActive = true
        progressLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor).isActive = true
        
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.bottomAnchor.constraint(equalTo: fileCountLabel.topAnchor, constant: -8).isActive = true
        scoreLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -12).isActive = true
        
        fileCountLabel.translatesAutoresizingMaskIntoConstraints = false
        fileCountLabel.bottomAnchor.constraint(equalTo: thumbImageView.bottomAnchor).isActive = true
        fileCountLabel.rightAnchor.constraint(equalTo: scoreLabel.rightAnchor).isActive = true
    }
    
    private func setupGesture() {
        contentView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressAction)))
    }
    
    private func setupNoticication() {
        NotificationCenter.default.addObserver(self, selector: #selector(downloadStatusChanged(notification:)), name: DownloadManager.DownloadPageSuccessNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadStatusChanged(notification:)), name: DownloadManager.DownloadStateChangedNotification, object: nil)
    }
    
    private func updateProgress() {
        progressLabel.text = ""
        guard let book = self.book else { return }
        guard DBManager.shared.contains(book: book, type: .download) else { return }
        
        switch DownloadManager.shared.downloadState(of: book) {
        case .before:
            break
        case .ing:
            progressLabel.text = "下载中：" + "\(book.downloadedFileCount)/\(book.fileCountNum)"
        case .suspend:
            progressLabel.text = "已暂停：" + "\(book.downloadedFileCount)/\(book.fileCountNum)"
        case .finish:
            progressLabel.text = "已下载"
        }
    }
    
    func updateWith(book: Book) {
        self.book = book
        thumbImageView.kf.setImage(with: URL(string: book.thumb))
        titleLabel.text = book.showTitle
        categoryLabel.text = book.category
        scoreLabel.text = book.rating
        fileCountLabel.text = "\(book.fileCountNum)页"
        updateProgress()
    }
    
    @objc
    private func downloadStatusChanged(notification: Notification) {
        guard let gid = notification.object as? Int, let book = self.book, book.gid == gid else { return }
        updateProgress()
    }
    
    @objc
    private func longPressAction() {
        longPressBlock?()
    }
}
