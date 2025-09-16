//
//  BookListViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Combine
import Kingfisher
import UIKit

final class BookListViewController: UITableViewController {
    enum BookListType {
        case home
        case history
        case download
    }
    
    private let type: BookListType
    private let viewModel: BookListViewModel
    private let footerView = BookListFooterView()
    private var dataSource: UITableViewDiffableDataSource<Int, Book>?
    private var cancelBag = Set<AnyCancellable>()
    
    init(type: BookListType) {
        self.type = type
        self.viewModel = BookListViewModel(type: type)
        super.init(style: .plain)
        hidesBottomBarWhenPushed = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCombine()
        setupDataSource()
        refreshData()
    }
    
    private func setupUI() {
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = 141
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = footerView
        tableView.register(BookListTableViewCell.self, forCellReuseIdentifier: NSStringFromClass(BookListTableViewCell.self))
        
        if type == .home {
            refreshControl = UIRefreshControl()
            refreshControl?.attributedTitle = NSAttributedString(string: "刷新中...")
            refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
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
    
    private func setupCombine() {
        viewModel.$books
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                guard let self else { return }
                if type == .history { navigationItem.rightBarButtonItem?.isEnabled = !$0.isEmpty }
                reloadTableViewData()
            })
            .store(in: &cancelBag)
        
        viewModel.$hint
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                footerView.hint = $0
            }
            .store(in: &cancelBag)
        
        viewModel.$isRefreshing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                if $0 {
                    tableView.setContentOffset(CGPoint(x: 0, y: -refreshControl!.frame.size.height * 3), animated: false)
                    refreshControl?.beginRefreshing()
                } else {
                    refreshControl?.endRefreshing()
                }
            }
            .store(in: &cancelBag)
    }
    
    private func setupDataSource() {
        dataSource = UITableViewDiffableDataSource<Int, Book>(tableView: tableView) { tableView, indexPath, book in
            let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(BookListTableViewCell.self), for: indexPath)
            if let cell = cell as? BookListTableViewCell {
                cell.updateWith(book: book)
                cell.longPressBlock = { [weak self] in
                    guard let self else { return }
                    showAlertVC(with: book)
                }
            }
            return cell
        }
    }
    
    private func reloadTableViewData() {
        guard let dataSource else { return }
        var snapshot = NSDiffableDataSourceSnapshot<Int, Book>()
        snapshot.appendSections([0])
        snapshot.appendItems(viewModel.books, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    @objc
    private func refreshData() {
        viewModel.refreshData()
    }
}

// MARK: UITableViewDelegate
extension BookListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let book = viewModel.books[indexPath.row]
        if !book.isOffensive {
            navigationController?.pushViewController(GalleryViewController(book: book), animated: true)
        } else {
            guard presentedViewController == nil else { return }
            let vc = UIAlertController(title: "警告", message: "此本含有令人不适内容(恶心猎奇)\n请确认是否一定要观看？", preferredStyle: .alert)
            vc.addAction(UIAlertAction(title: "确认", style: .default, handler: { [weak self] _ in
                guard let self else { return }
                navigationController?.pushViewController(GalleryViewController(book: book), animated: true)
            }))
            vc.addAction(UIAlertAction(title: "算了", style: .cancel))
            present(vc, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let prefetchPoint = Int(Double(viewModel.books.count) * 0.7)
        if indexPath.row >= prefetchPoint { viewModel.loadMoreData() }
    }
}

// MARK: TapNavBarRightItem
extension BookListViewController {
    @objc
    private func tapNavBarRightItem() {
        switch type {
        case .home:
            navigationController?.pushViewController(SearchViewController(), animated: true)
        case .history:
            guard presentedViewController == nil else { return }
            let vc = UIAlertController(title: "提示", message: "确定要清除所有历史记录吗？\n（不会影响已下载内容）", preferredStyle: .alert)
            vc.addAction(UIAlertAction(title: "清除", style: .default, handler: { _ in
                DBManager.shared.books(of: .history)
                    .filter { !DBManager.shared.contains(gid: $0.gid, of: .download) }
                    .forEach { DownloadManager.shared.remove($0) }
                DBManager.shared.removeAll(type: .history)
            }))
            vc.addAction(UIAlertAction(title: "取消", style: .cancel))
            present(vc, animated: true)
        case .download:
            break
        }
    }
}

// MARK: AlertVC
extension BookListViewController {
    private func showAlertVC(with book: Book) {
        Task {
            guard presentedViewController == nil else { return }
            let vc = UIAlertController(title: "", message: book.showTitle, preferredStyle: .alert)
            
            if !DBManager.shared.contains(gid: book.gid, of: .download) {
                vc.addAction(UIAlertAction(title: "下载", style: .default, handler: { _ in
                    DownloadManager.shared.download(book)
                    DBManager.shared.insert(book: book, of: .download)
                }))
            } else {
                let state = await DownloadManager.shared.downloadState(of: book)
                switch state {
                case .before, .suspend:
                    vc.addAction(UIAlertAction(title: "下载", style: .default, handler: { _ in
                        DownloadManager.shared.download(book)
                    }))
                case .ing:
                    vc.addAction(UIAlertAction(title: "暂停", style: .default, handler: { _ in
                        DownloadManager.shared.suspend(book)
                    }))
                case .finish:
                    break
                }
                
                if state != .before && type != .history {
                    vc.addAction(UIAlertAction(title: "删除下载", style: .default, handler: { _ in
                        DownloadManager.shared.remove(book)
                        DBManager.shared.remove(book: book, of: .download)
                    }))
                }
            }
            
            if type == .history {
                vc.addAction(UIAlertAction(title: "删除历史", style: .default, handler: { _ in
                    if !DBManager.shared.contains(gid: book.gid, of: .download) {
                        DownloadManager.shared.remove(book)
                    }
                    DBManager.shared.remove(book: book, of: .history)
                }))
            }
            
            if let url = URL(string: book.webURLString(with: SettingManager.shared.isLoginSubject.value ? .ExHentai : .EHentai)) {
                vc.addAction(UIAlertAction(title: "打开原网页", style: .default, handler: { [weak self] _ in
                    guard let self else { return }
                    var image: UIImage?
                    if let thumb = book.thumb {
                        image = ImageCache.default.retrieveImageInMemoryCache(forKey: thumb)
                    }
                    navigationController?.pushViewController(WebViewController(url: url, shareItem: (book.showTitle, image)), animated: true)
                }))
            }
            
            if !book.tags.isEmpty {
                vc.addAction(UIAlertAction(title: "搜索相关Tag", style: .default, handler: { [weak self] _ in
                    guard let self else { return }
                    navigationController?.pushViewController(TagViewController(book: book), animated: true)
                }))
            }
            
            vc.addAction(UIAlertAction(title: "没事", style: .cancel))
            present(vc, animated: true)
        }
    }
}
