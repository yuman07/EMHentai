//
//  BookListViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import UIKit

enum BookListType {
    case Home
    case History
    case Download
}

class BookListViewController: UITableViewController {
    let type: BookListType
    var searchInfo = SearchInfo() {
        didSet {
            hasNext = true
        }
    }
    var hasNext = true
    var books = [Book]()
    
    private let footerView = BookListFooterView()
    
    init(type: BookListType) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if type != .Home {
            self.refreshData(with: nil)
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 150
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.tableFooterView = footerView
        tableView.register(BookListTableViewCell.self, forCellReuseIdentifier: NSStringFromClass(BookListTableViewCell.self))
        
        refreshControl = UIRefreshControl()
        refreshControl?.attributedTitle = NSAttributedString(string: "刷新中...")
        refreshControl?.addTarget(self, action: #selector(setupData), for: .valueChanged)
        
        switch type {
        case .Home:
            navigationItem.title = "主页"
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(tapNavBarRightItem))
        case .History:
            navigationItem.title = "历史"
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "清除历史", style: .plain, target: self, action: #selector(tapNavBarRightItem))
        case .Download:
            navigationItem.title = "下载"
        }
    }
    
    @objc
    private func setupData() {
        switch type {
        case .Home:
            refreshData(with: searchInfo)
        case .History:
            refreshData(with: nil)
        case .Download:
            refreshData(with: nil)
        }
    }
}

// MARK: load Data
extension BookListViewController {
    func refreshData(with searchInfo: SearchInfo?) {
        refreshControl?.beginRefreshing()
        tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - refreshControl!.frame.size.height), animated: true)
        switch type {
        case .Home:
            guard let searchInfo = searchInfo else { refreshControl?.endRefreshing(); return }
            self.searchInfo = searchInfo
            SearchManager.shared.searchWith(info: searchInfo) { [weak self] books, isHappenNetError in
                guard let self = self else { return }
                self.books = books
                self.hasNext = !books.isEmpty
                if isHappenNetError {
                    self.footerView.hint = .netError
                } else {
                    self.footerView.hint = self.hasNext ? .none : .noData
                }
                if !self.tableView.visibleCells.isEmpty {
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                }
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            }
        case .History, .Download:
            books = type == .History ? DBManager.shared.booksMap[.history]! : DBManager.shared.booksMap[.download]!
            hasNext = false
            footerView.hint = books.isEmpty ? .noData : .noMoreData
            self.tableView.reloadData()
            refreshControl?.endRefreshing()
        }
    }
    
    func loadMoreData() {
        guard type == .Home, hasNext else { return }
        var nextInfo = searchInfo
        nextInfo.pageIndex += 1
        SearchManager.shared.searchWith(info: nextInfo) { [weak self] books, isHappenNetError in
            guard let self = self else { return }
            if books.isEmpty {
                self.hasNext = false
            } else {
                self.hasNext = true
                self.books += books
                self.searchInfo.pageIndex += 1
                self.tableView.reloadData()
            }
            if isHappenNetError {
                self.footerView.hint = .netError
            } else {
                self.footerView.hint = self.hasNext ? .none : .noMoreData
            }
        }
    }
}

// MARK: TapNavBarRightItem
extension BookListViewController {
    @objc
    private func tapNavBarRightItem() {
        switch type {
        case .Home:
            let searchVC = SearchViewController()
            searchVC.bookVC = self
            navigationController?.pushViewController(searchVC, animated: true)
        case .History:
            DBManager.shared.removeAll(type: .history)
            refreshData(with: nil)
            break
        case .Download:
            break
        }
    }
}

// MARK: AlertVC
extension BookListViewController {
    private func makeAlertVC(with book: Book) -> UIAlertController {
        let vc = UIAlertController(title: "", message: book.showTitle, preferredStyle: .alert)
        let state = DownloadManager.shared.downloadState(of: book)
        
        switch state {
        case .before, .suspend:
            vc.addAction(UIAlertAction(title: "下载", style: .default, handler: { _ in
                DownloadManager.shared.download(book: book)
                DBManager.shared.insertIfNotExist(book: book, at: .download)
            }))
        case .ing:
            vc.addAction(UIAlertAction(title: "暂停", style: .default, handler: { _ in
                DownloadManager.shared.suspend(book: book)
            }))
        case .finish:
            break
        }
        if state != .before {
            vc.addAction(UIAlertAction(title: "删除", style: .default, handler: { _ in
                DownloadManager.shared.remove(book: book)
            }))
        }
        
        vc.addAction(UIAlertAction(title: "详细信息", style: .default, handler: { _ in
            print("查看详细信息~")
        }))
        vc.addAction(UIAlertAction(title: "没事", style: .cancel, handler: nil))
        return vc
    }
}

// MARK: UITableViewDataSource
extension BookListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        books.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(BookListTableViewCell.self), for: indexPath)
        if let cell = cell as? BookListTableViewCell, indexPath.row < books.count {
            let book = books[indexPath.row]
            cell.updateWith(book: book)
            cell.longPressBlock = {
                self.present(self.makeAlertVC(with: book), animated: true, completion: nil)
            }
        }
        return cell
    }
}

// MARK: UITableViewDelegate
extension BookListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row < books.count {
            navigationController?.pushViewController(GalleryViewController(book: books[indexPath.row]), animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let prefetchPoint = Int(Double(books.count) * 0.7)
        if indexPath.row >= prefetchPoint {
            loadMoreData()
        }
    }
}

