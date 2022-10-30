//
//  BookcaseTableViewCell.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/17.
//

import UIKit
import Kingfisher
import Combine

final class BookcaseTableViewCell: UITableViewCell {
    var longPressBlock: (() -> Void)?
    
    private var book: Book?
    private var cancelBag = Set<AnyCancellable>()
    
    private let thumbImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel = {
        let label = UILabel()
        label.numberOfLines = 5
        label.lineBreakMode = .byTruncatingTail
        label.font = .systemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let categoryLabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressLabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scoreLabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let fileCountLabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupGesture()
        setupCombine()
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
        
        thumbImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12).isActive = true
        thumbImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        thumbImageView.widthAnchor.constraint(equalToConstant: 125).isActive = true
        thumbImageView.heightAnchor.constraint(equalToConstant: 125).isActive = true
        
        titleLabel.topAnchor.constraint(equalTo: thumbImageView.topAnchor).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: thumbImageView.rightAnchor, constant: 8).isActive = true
        titleLabel.rightAnchor.constraint(lessThanOrEqualTo: scoreLabel.rightAnchor).isActive = true
        
        categoryLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8).isActive = true
        categoryLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor).isActive = true
        
        progressLabel.bottomAnchor.constraint(equalTo: fileCountLabel.bottomAnchor).isActive = true
        progressLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor).isActive = true
        
        scoreLabel.bottomAnchor.constraint(equalTo: fileCountLabel.topAnchor, constant: -8).isActive = true
        scoreLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -12).isActive = true
        
        fileCountLabel.bottomAnchor.constraint(equalTo: thumbImageView.bottomAnchor).isActive = true
        fileCountLabel.rightAnchor.constraint(equalTo: scoreLabel.rightAnchor).isActive = true
    }
    
    private func setupGesture() {
        contentView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressAction)))
    }
    
    private func setupCombine() {
        DownloadManager.shared.downloadPageSuccessSubject.map(\.book)
            .merge(with: DownloadManager.shared.downloadStateChangedSubject.map(\.book))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] obj in
                guard let self, let book = self.book, obj.gid == book.gid else { return }
                self.updateProgress()
            }
            .store(in: &cancelBag)
        DBManager.shared.DBChangedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateProgress()
            }
            .store(in: &cancelBag)
    }
    
    private func updateProgress() {
        Task {
            guard let book, DBManager.shared.contains(gid: book.gid, of: .download) else {
                progressLabel.text = ""
                return
            }
            
            switch await DownloadManager.shared.downloadState(of: book) {
            case .before:
                progressLabel.text = ""
            case .ing:
                progressLabel.text = "下载中：" + "\(book.downloadedFileCount)/\(book.fileCountNum)"
            case .suspend:
                progressLabel.text = "已暂停：" + "\(book.downloadedFileCount)/\(book.fileCountNum)"
            case .finish:
                progressLabel.text = "已下载"
            }
        }
    }
    
    func updateWith(book: Book) {
        self.book = book
        if let image = UIImage(filePath: book.coverImagePath) {
            thumbImageView.image = image
        } else {
            thumbImageView.kf.setImage(with: URL(string: book.thumb))
        }
        titleLabel.text = book.showTitle
        categoryLabel.text = book.category
        scoreLabel.text = book.rating
        fileCountLabel.text = "\(book.fileCountNum)页"
        progressLabel.text = ""
        updateProgress()
    }
    
    @objc
    private func longPressAction() {
        longPressBlock?()
    }
}
