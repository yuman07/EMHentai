//
//  BookListTableViewCell.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/17.
//

import Combine
import Kingfisher
import UIKit

final class BookListTableViewCell: UITableViewCell {
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
            thumbImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            thumbImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbImageView.widthAnchor.constraint(equalToConstant: 125),
            thumbImageView.heightAnchor.constraint(equalToConstant: 125),
            
            titleLabel.topAnchor.constraint(equalTo: thumbImageView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: thumbImageView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: scoreLabel.trailingAnchor),
            
            categoryLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            categoryLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            
            progressLabel.bottomAnchor.constraint(equalTo: fileCountLabel.bottomAnchor),
            progressLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            
            scoreLabel.bottomAnchor.constraint(equalTo: fileCountLabel.topAnchor, constant: -8),
            scoreLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            
            fileCountLabel.bottomAnchor.constraint(equalTo: thumbImageView.bottomAnchor),
            fileCountLabel.trailingAnchor.constraint(equalTo: scoreLabel.trailingAnchor),
        ])
    }
    
    private func setupGesture() {
        contentView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressAction)))
    }
    
    private func setupCombine() {
        DownloadManager.shared.downloadPageSuccessSubject.map(\.book)
            .merge(with: DownloadManager.shared.downloadStateChangedSubject.map(\.book))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self, let book, $0.gid == book.gid else { return }
                updateProgress()
            }
            .store(in: &cancelBag)
        DBManager.shared.dbChangedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                updateProgress()
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
                progressLabel.text = "下载中：" + "\(book.downloadedImgCount)/\(book.fileCount)"
            case .suspend:
                progressLabel.text = "已暂停：" + "\(book.downloadedImgCount)/\(book.fileCount)"
            case .finish:
                progressLabel.text = "已下载"
            }
        }
    }
    
    func updateWith(book: Book) {
        self.book = book
        if let image = UIImage(filePath: book.coverImagePath) {
            thumbImageView.image = image
        } else if let thumb = book.thumb {
            thumbImageView.kf.setImage(with: URL(string: thumb))
        }
        titleLabel.text = book.showTitle
        categoryLabel.text = book.category
        scoreLabel.text = book.rating
        fileCountLabel.text = "\(book.fileCount)页"
        progressLabel.text = ""
        updateProgress()
    }
    
    @objc
    private func longPressAction() {
        longPressBlock?()
    }
}
