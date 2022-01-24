//
//  TagViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/24.
//

import Foundation
import UIKit

class TagViewController: UITableViewController {
    
    private let book: Book
    private var selectedTags = [String]()
    
    weak var bookVC: BookListViewController?
    
    init(book: Book) {
        self.book = book
        super.init(style: .plain)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = 44
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.delegate = self
        tableView.dataSource = self
        tableView.bounces = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        
        navigationItem.title = "选择相关Tag进行搜索"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "GO", style: .done, target: self, action: #selector(searchAction))
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    @objc
    private func searchAction() {
        var searchInfo = SearchInfo()
        searchInfo.keyWord = selectedTags.joined(separator: " ")
        searchInfo.saveDB()
        bookVC?.refreshData(with: searchInfo)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: UITableViewDataSource
extension TagViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        book.tags.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
        let tag = book.tags[indexPath.row]
        cell.textLabel?.text = tag + TranslateManager.shared.translate(word: tag)
        return cell
    }
}

// MARK: UITableViewDelegate
extension TagViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        if cell.accessoryType == .none {
            cell.accessoryType = .checkmark
            selectedTags.append(book.tags[indexPath.row])
        } else {
            cell.accessoryType = .none
            selectedTags.removeAll(where: { $0 == book.tags[indexPath.row] })
        }
        navigationItem.rightBarButtonItem?.isEnabled = !selectedTags.isEmpty
    }
}
