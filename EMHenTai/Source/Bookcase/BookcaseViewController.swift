//
//  BookcaseViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import UIKit
import Kingfisher

final class BookcaseViewController: UITableViewController {
    enum BookcaseType {
        case home
        case history
        case download
    }
    
    enum CellLayout: Int {
        case normal
        case thumbnail
    }
    
    private let type: BookcaseType
    private let footerView = BookcaseFooterView()
    
    private var searchInfo: SearchInfo?
    private var books = [Book]()
    private var hasMore = false
    private var cellLayout = CellLayout.normal
    
    init(type: BookcaseType) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDelegate()
        setupData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if type != .home { self.refreshData(with: nil) }
    }
    
    private func setupUI() {
        tableView.backgroundColor = .systemGroupedBackground
        tableView.estimatedRowHeight = 150
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.tableFooterView = footerView
        tableView.register(BookcaseTableViewCell.self, forCellReuseIdentifier: NSStringFromClass(BookcaseTableViewCell.self))
        
        if type == .home {
            refreshControl = UIRefreshControl()
            refreshControl?.attributedTitle = NSAttributedString(string: "刷新中...")
            refreshControl?.addTarget(self, action: #selector(setupData), for: .valueChanged)
        }
        
        switch type {
        case .home:
            navigationItem.title = "主页"
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(tapNavBarRightItem))
        case .history:
            navigationItem.title = "历史"
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(symbol: .trash), style: .plain, target: self, action: #selector(tapNavBarRightItem))
        case .download:
            navigationItem.title = "下载"
        }
    }
    
    private func setupDelegate() {
        if type == .home { SearchManager.shared.delegate = self }
    }
    
    @objc
    private func setupData() {
        switch type {
        case .home:
            refreshData(with: SearchInfo())
        case .history, .download:
            refreshData(with: nil)
        }
    }
}

// MARK: SearchManagerCallbackDelegate
extension BookcaseViewController: SearchManagerCallbackDelegate {
    @MainActor
    func searchStartCallback(searchInfo: SearchInfo) async {
        guard searchInfo.pageIndex == 0 else { return }
        searchInfo.saveDB()
        self.tableView.setContentOffset(CGPoint(x: 0, y: -self.refreshControl!.frame.size.height * 3), animated: false)
        self.refreshControl?.beginRefreshing()
    }
    
    @MainActor
    func searchFinishCallback(searchInfo: SearchInfo, result: Result<[Book], SearchManager.SearchError>) async {
        switch result {
        case .success(let books):
            self.hasMore = !books.isEmpty
            if searchInfo.pageIndex == 0 { self.books = books }
            else { self.books += books }
            if !self.hasMore {
                self.footerView.hint = self.books.isEmpty ? .noData : .noMoreData
            } else {
                self.footerView.hint = .loading
            }
        case .failure(let error):
            switch error {
            case .netError:
                self.footerView.hint = .netError
            case .ipError:
                self.footerView.hint = .ipError
            }
        }
        
        self.searchInfo = searchInfo
        self.refreshControl?.endRefreshing()
        self.tableView.reloadData()
    }
}

// MARK: load Data
extension BookcaseViewController {
    private func refreshData(with searchInfo: SearchInfo?) {
        switch type {
        case .home:
            guard let searchInfo = searchInfo else { return }
            SearchManager.shared.searchWith(info: searchInfo)
        case .history, .download:
            books = (type == .history) ? DBManager.shared.books(of: .history) : DBManager.shared.books(of: .download)
            if (type == .history) { navigationItem.rightBarButtonItem?.isEnabled = !books.isEmpty }
            footerView.hint = books.isEmpty ? .noData : .noMoreData
            self.tableView.reloadData()
        }
    }
    
    private func loadMoreData() {
        guard type == .home, var nextInfo = searchInfo, hasMore else { return }
        nextInfo.pageIndex += 1
        SearchManager.shared.searchWith(info: nextInfo)
    }
}

// MARK: TapNavBarRightItem
extension BookcaseViewController {
    @objc
    private func tapNavBarRightItem() {
        switch type {
        case .home:
            navigationController?.pushViewController(SearchViewController(), animated: true)
        case .history:
            guard !books.isEmpty else { return }
            let vc = UIAlertController(title: "提示", message: "确定要清除所有历史记录吗？\n(不会影响已下载内容)", preferredStyle: .alert)
            vc.addAction(UIAlertAction(title: "清除", style: .default, handler: { _ in
                DBManager.shared.books(of: .history)
                    .filter { !DBManager.shared.contains(gid: $0.gid, of: .download) }
                    .forEach { DownloadManager.shared.remove(book: $0) }
                DBManager.shared.removeAll(type: .history)
                self.refreshData(with: nil)
            }))
            vc.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            present(vc, animated: true, completion: nil)
        case .download:
            break
        }
    }
}

// MARK: AlertVC
extension BookcaseViewController {
    private func showAlertVC(with book: Book) {
        Task {
            let vc = UIAlertController(title: "", message: book.showTitle, preferredStyle: .alert)
            
            if !DBManager.shared.contains(gid: book.gid, of: .download) {
                vc.addAction(UIAlertAction(title: "下载", style: .default, handler: { _ in
                    DownloadManager.shared.download(book: book)
                    DBManager.shared.insert(book: book, of: .download)
                    self.tableView.reloadData()
                }))
            } else {
                let state = await DownloadManager.shared.downloadState(of: book)
                switch state {
                case .before, .suspend:
                    vc.addAction(UIAlertAction(title: "下载", style: .default, handler: { _ in
                        DownloadManager.shared.download(book: book)
                    }))
                case .ing:
                    vc.addAction(UIAlertAction(title: "暂停", style: .default, handler: { _ in
                        DownloadManager.shared.suspend(book: book)
                    }))
                case .finish:
                    break
                }
                
                if state != .before && type != .history {
                    vc.addAction(UIAlertAction(title: "删除下载", style: .default, handler: { _ in
                        DownloadManager.shared.remove(book: book)
                        DBManager.shared.remove(book: book, of: .download)
                        if self.type == .download { self.refreshData(with: nil) }
                    }))
                }
            }
            
            if type == .history {
                vc.addAction(UIAlertAction(title: "删除历史", style: .default, handler: { _ in
                    if !DBManager.shared.contains(gid: book.gid, of: .download) {
                        DownloadManager.shared.remove(book: book)
                    }
                    DBManager.shared.remove(book: book, of: .history)
                    self.refreshData(with: nil)
                }))
            }
            
            if !book.tags.isEmpty {
                vc.addAction(UIAlertAction(title: "搜索相关Tag", style: .default, handler: { _ in
                    self.navigationController?.pushViewController(TagViewController(book: book), animated: true)
                }))
            }
            
            if let url = URL(string: book.webURLString(with: SettingManager.shared.isLogin ? .ExHentai : .EHentai)) {
                vc.addAction(UIAlertAction(title: "打开原网页", style: .default, handler: { _ in
                    let image = ImageCache.default.retrieveImageInMemoryCache(forKey: book.thumb)
                    self.navigationController?.pushViewController(WebViewController(url: url, shareItem: (book.showTitle, image)), animated: true)
                }))
            }
            
            vc.addAction(UIAlertAction(title: "没事", style: .cancel, handler: nil))
            
            present(vc, animated: true, completion: nil)
        }
    }
}

// MARK: UITableViewDataSource
extension BookcaseViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        books.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(BookcaseTableViewCell.self), for: indexPath)
        if let cell = cell as? BookcaseTableViewCell, indexPath.row < books.count {
            let book = books[indexPath.row]
            cell.updateWith(book: book)
            cell.longPressBlock = { [weak self] in
                self?.showAlertVC(with: book)
            }
        }
        return cell
    }
}

// MARK: UITableViewDelegate
extension BookcaseViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < books.count else { return }
        let book = books[indexPath.row]
        if !book.isOffensive {
            navigationController?.pushViewController(GalleryViewController(book: book), animated: true)
        } else {
            let vc = UIAlertController(title: "警告", message: "此本含有令人不适内容(恶心猎奇)\n请确认是否一定要观看？", preferredStyle: .alert)
            vc.addAction(UIAlertAction(title: "确认", style: .default, handler: { _ in
                self.navigationController?.pushViewController(GalleryViewController(book: book), animated: true)
            }))
            vc.addAction(UIAlertAction(title: "算了", style: .cancel, handler: nil))
            present(vc, animated: true, completion: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let prefetchPoint = Int(Double(books.count) * 0.7)
        if indexPath.row >= prefetchPoint { loadMoreData() }
    }
}

