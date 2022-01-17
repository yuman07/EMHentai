//
//  ListViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import UIKit

enum ListStyle {
    case Home
    case History
    case Download
}

class ListViewController: UIViewController {
    
    let style: ListStyle
    
    var books = [Book]()
    
    let tableView: UITableView = {
        let table = UITableView()
        table.estimatedRowHeight = 180
        table.estimatedSectionHeaderHeight = 0
        table.estimatedSectionFooterHeight = 0
        table.register(BookTableViewCell.self, forCellReuseIdentifier: NSStringFromClass(BookTableViewCell.self))
        return table
    }()
    
    init(style: ListStyle) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.style = .Home
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
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }
    
    private func setupNavBar() {
        switch style {
        case .Home:
            navigationItem.title = "主页"
        case .History:
            navigationItem.title = "历史"
        case .Download:
            navigationItem.title = "下载"
        }
    }
    
    private func setupData() {
        refreshDataWith(searchInfo: SearchInfo())
    }
    
    func refreshDataWith(searchInfo: SearchInfo) {
        SearchManager.shared.searchWith(info: searchInfo) { [weak self] books in
            guard let self = self else { return }
            self.books = books
            self.tableView.reloadData()
            print(books.count)
        }
    }
}

extension ListViewController: UITableViewDataSource {
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

extension ListViewController: UITableViewDelegate {
    
}
