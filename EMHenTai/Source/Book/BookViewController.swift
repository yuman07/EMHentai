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

class BookViewController: UIViewController {
    let type: BookVCType
    var searchInfo: SearchInfo? {
        didSet {
            hasNext = true
        }
    }
    var hasNext = true
    var books = [Book]()
    
    lazy var tableView: UITableView = {
        let table = UITableView()
        table.delegate = self
        table.dataSource = self
        table.prefetchDataSource = self
        table.estimatedRowHeight = 150
        table.estimatedSectionHeaderHeight = 0
        table.estimatedSectionFooterHeight = 0
        table.register(BookTableViewCell.self, forCellReuseIdentifier: NSStringFromClass(BookTableViewCell.self))
        return table
    }()
    
    init(type: BookVCType) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.type = .Home
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavBar()
        setupData()
    }
    
    private func setupView() {
        view.backgroundColor = .white
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
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
    
    private func setupData() {
        switch type {
        case .Home:
            refreshData(with: SearchInfo())
        case .History:
            refreshData(with: nil)
        case .Download:
            refreshData(with: nil)
        }
    }
    
    func refreshData(with searchInfo: SearchInfo?) {
        switch type {
        case .Home:
            guard let searchInfo = searchInfo else { return }
            self.searchInfo = searchInfo
            SearchManager.shared.searchWith(info: searchInfo) { [weak self] books in
                guard let self = self else { return }
                self.books = books
                self.hasNext = !books.isEmpty
                self.tableView.reloadData()
            }
        case .History:
            break
        case .Download:
            break
        }
    }
    
    func loadMoreData() {
        guard var searchInfo = self.searchInfo, type == .Home, hasNext else { return }
        searchInfo.pageIndex += 1
        SearchManager.shared.searchWith(info: searchInfo) { [weak self] books in
            guard let self = self else { return }
            if books.isEmpty {
                self.hasNext = false
            } else {
                self.hasNext = true
                self.books += books
                self.searchInfo?.pageIndex += 1
                self.tableView.reloadData()
            }
        }
    }
}

extension BookViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(BookTableViewCell.self), for: indexPath)
        if let cell = cell as? BookTableViewCell, indexPath.row < books.count {
            cell.updateWith(book: books[indexPath.row])
        }
        return cell
    }
}

extension BookViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row < books.count {
            navigationController?.pushViewController(GalleryViewController(book: books[indexPath.row]), animated: true)
        }
    }
}

extension BookViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let prefetchPoint = Int(Double(books.count) * 0.8)
        if let last = indexPaths.last, last.row >= prefetchPoint {
            loadMoreData()
        }
    }
}

// Home
extension BookViewController {
    @objc
    func jumpToSearchPage() {
        let searchVC = SearchViewController()
        searchVC.listVC = self
        navigationController?.pushViewController(searchVC, animated: true)
    }
}
