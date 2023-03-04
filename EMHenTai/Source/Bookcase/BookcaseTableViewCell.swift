//
//  BookcaseTableViewCell.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/17.
//

import Combine
import UIKit

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
        
        NSLayoutConstraint.activate([
            thumbImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12),
            thumbImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbImageView.widthAnchor.constraint(equalToConstant: 125),
            thumbImageView.heightAnchor.constraint(equalToConstant: 125),
            
            titleLabel.topAnchor.constraint(equalTo: thumbImageView.topAnchor),
            titleLabel.leftAnchor.constraint(equalTo: thumbImageView.rightAnchor, constant: 8),
            titleLabel.rightAnchor.constraint(lessThanOrEqualTo: scoreLabel.rightAnchor),
            
            categoryLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            categoryLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
            
            progressLabel.bottomAnchor.constraint(equalTo: fileCountLabel.bottomAnchor),
            progressLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
            
            scoreLabel.bottomAnchor.constraint(equalTo: fileCountLabel.topAnchor, constant: -8),
            scoreLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -12),
            
            fileCountLabel.bottomAnchor.constraint(equalTo: thumbImageView.bottomAnchor),
            fileCountLabel.rightAnchor.constraint(equalTo: scoreLabel.rightAnchor),
        ])
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
                progressLabel.text = "下载中：" + "\(book.downloadedImgCount)/\(book.contentImgCount)"
            case .suspend:
                progressLabel.text = "已暂停：" + "\(book.downloadedImgCount)/\(book.contentImgCount)"
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
        fileCountLabel.text = "\(book.contentImgCount)页"
        progressLabel.text = ""
        updateProgress()
    }
    
    @objc
    private func longPressAction() {
        longPressBlock?()
    }
}
