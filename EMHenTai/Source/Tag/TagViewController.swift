//
//  TagViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/24.
//

import Foundation
import UIKit

final class TagViewController: UITableViewController {
    private let book: Book
    private var selectedTags = [String]()
    
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
        SearchManager.shared.searchWith(info: searchInfo)
        navigationController?.popViewController(animated: false)
        (UIApplication.shared.keyWindow?.rootViewController as? UITabBarController)?.selectedIndex = 0   
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
        cell.textLabel?.text = tag + TranslateManager.shared.translateEn(tag)
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

