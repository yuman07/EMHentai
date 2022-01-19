//
//  BookViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import UIKit

enum BookVCType {
    case Home
    case History
    case Download
}

class BookViewController: UITableViewController {
    let type: BookVCType
    var searchInfo = SearchInfo() {
        didSet {
            hasNext = true
        }
    }
    var hasNext = true
    var books = [Book]()
    
    init(type: BookVCType) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavBar()
        setupData()
    }
    
    private let footerView = BookFooterView()
    
    private func setupView() {
        view.backgroundColor = .white
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 150
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.tableFooterView = footerView
        tableView.register(BookTableViewCell.self, forCellReuseIdentifier: NSStringFromClass(BookTableViewCell.self))
        
        refreshControl = UIRefreshControl()
        refreshControl?.attributedTitle = NSAttributedString(string: "刷新中...")
        refreshControl?.addTarget(self, action: #selector(setupData), for: .valueChanged)
    }
    
    private func setupNavBar() {
        switch type {
        case .Home:
            navigationItem.title = "主页"
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(jumpToSearchPage))
        case .History:
            navigationItem.title = "历史"
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
                    self.footerView.update(hint: .netError)
                } else {
                    self.footerView.update(hint: self.hasNext ? .none : .noData)
                }
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            }
        case .History:
            refreshControl?.endRefreshing()
        case .Download:
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
                self.footerView.update(hint: .netError)
            } else {
                self.footerView.update(hint: self.hasNext ? .none : .noMoreData)
            }
        }
    }
}

// UITableViewDataSource
extension BookViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(BookTableViewCell.self), for: indexPath)
        if let cell = cell as? BookTableViewCell, indexPath.row < books.count {
            cell.updateWith(book: books[indexPath.row])
        }
        return cell
    }
}

// UITableViewDelegate
extension BookViewController {
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

// Home
extension BookViewController {
    @objc
    func jumpToSearchPage() {
        let searchVC = SearchViewController()
        searchVC.bookVC = self
        navigationController?.pushViewController(searchVC, animated: true)
    }
}
