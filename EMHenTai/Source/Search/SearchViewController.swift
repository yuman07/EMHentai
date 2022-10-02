//
//  SearchViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/17.
//

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
    
    private var searchInfo = SearchInfo() {
        didSet {
            navigationItem.rightBarButtonItem?.isEnabled =
                !searchInfo.categories.isEmpty && (searchInfo.source == .EHentai || SettingManager.shared.loginStateSubject.value)
            
            if oldValue.keyWord == searchInfo.keyWord { tableView.reloadData() }
        }
    }
    
    lazy var doubleTapCategoryGestureRecognizer = {
        let gr = UITapGestureRecognizer(target: self, action: #selector(doubleTapCategoryHeaderAction))
        gr.numberOfTapsRequired = 2
        return gr
    }()
    
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
        tableView.sectionHeaderHeight = 40
        tableView.sectionFooterHeight = 0
        tableView.bounces = false
        tableView.register(SearchTextFieldCell.self, forCellReuseIdentifier: NSStringFromClass(SearchTextFieldCell.self))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: NSStringFromClass(UITableViewHeaderFooterView.self))
    }
    
    @objc
    private func doubleTapCategoryHeaderAction() {
        if searchInfo.categories.isEmpty {
            searchInfo.categories = SearchInfo.Category.allCases
        } else {
            searchInfo.categories = []
        }
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
        Self.sections.count
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
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: NSStringFromClass(UITableViewHeaderFooterView.self))
        header?.textLabel?.text = SearchViewController.sections[section]
        header?.removeGestureRecognizer(doubleTapCategoryGestureRecognizer)
        if section == 4 { header?.addGestureRecognizer(doubleTapCategoryGestureRecognizer) }
        return header
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cls = indexPath.section == 0 ? SearchTextFieldCell.self : UITableViewCell.self
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(cls), for: indexPath)
        cell.selectionStyle = .none
        
        switch indexPath.section {
        case 0:
            if let cell = cell as? SearchTextFieldCell {
                if cell.searchTextField.text?.isEmpty ?? true {
                    cell.searchTextField.text = searchInfo.keyWord
                }
                cell.textChangedAction = { [weak self] text in
                    guard let self, self.searchInfo.keyWord != text else { return }
                    self.searchInfo.keyWord = text
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
    }
}
