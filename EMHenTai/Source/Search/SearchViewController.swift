//
//  SearchViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/17.
//

import Foundation
import UIKit

protocol searchVCItemDataSource {
    var searchItemTitle: String { get }
}

final class SearchViewController: UITableViewController {
    private static let sections = [
        "关键词",
        "数据源",
        "语言",
        "评分",
        "分类",
    ]
    
    private var searchInfo = SearchInfo()
    
    init() {
        super.init(style: .grouped)
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
        navigationItem.title = "搜索"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "GO", style: .done, target: self, action: #selector(searchAction))
        
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = 44
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.delegate = self
        tableView.dataSource = self
        tableView.bounces = false
        tableView.register(TextFieldTableViewCell.self, forCellReuseIdentifier: NSStringFromClass(TextFieldTableViewCell.self))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
    }
    
    @objc
    private func searchAction() {
        SearchManager.shared.searchWith(info: searchInfo)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: UITableViewDataSource
extension SearchViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        SearchViewController.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return SearchInfo.Source.allCases.count
        case 2:
            return SearchInfo.Language.allCases.count
        case 3:
            return SearchInfo.Rating.allCases.count
        case 4:
            return SearchInfo.Category.allCases.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        SearchViewController.sections[section]
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        30
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cls = indexPath.section == 0 ? TextFieldTableViewCell.self : UITableViewCell.self
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(cls), for: indexPath)
        cell.selectionStyle = .none
        
        switch indexPath.section {
        case 0:
            if let cell = cell as? TextFieldTableViewCell {
                cell.searchTextField.text = searchInfo.keyWord
                cell.textChangeAction = { [weak self] text in
                    self?.searchInfo.keyWord = text
                }
            }
        case 1:
            let source = SearchInfo.Source.allCases[indexPath.row]
            cell.textLabel?.text = source.searchItemTitle
            cell.accessoryType = (searchInfo.source == source) ? .checkmark : .none
        case 2:
            let language = SearchInfo.Language.allCases[indexPath.row]
            cell.textLabel?.text = language.searchItemTitle
            cell.accessoryType = (searchInfo.language == language) ? .checkmark : .none
        case 3:
            let rating = SearchInfo.Rating.allCases[indexPath.row]
            cell.textLabel?.text = rating.searchItemTitle
            cell.accessoryType = (searchInfo.rating == rating) ? .checkmark : .none
        case 4:
            let category = SearchInfo.Category.allCases[indexPath.row]
            cell.textLabel?.text = category.searchItemTitle
            cell.accessoryType = searchInfo.categories.contains(category) ? .checkmark : .none
        default:
            break
        }
        return cell
    }
}

// MARK: UITableViewDelegate
extension SearchViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            break
        case 1:
            searchInfo.source = SearchInfo.Source.allCases[indexPath.row]
        case 2:
            searchInfo.language = SearchInfo.Language.allCases[indexPath.row]
        case 3:
            searchInfo.rating = SearchInfo.Rating.allCases[indexPath.row]
        case 4:
            let category = SearchInfo.Category.allCases[indexPath.row]
            if searchInfo.categories.contains(category) {
                searchInfo.categories.removeAll(where: { $0 == category })
            } else {
                searchInfo.categories.append(category)
            }
        default:
            break
        }
        tableView.reloadSections([indexPath.section], with: .none)
    }
}
