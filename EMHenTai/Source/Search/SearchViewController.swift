//
//  SearchViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/17.
//

import UIKit

protocol SearchVCItemDataSource {
    var searchItemTitle: String { get }
}

final class SearchViewController: UITableViewController {
    private enum SectionType: String, CaseIterable {
        case keyword = "关键词"
        case dateSource = "数据源"
        case language = "语言"
        case rating = "评分"
        case category = "分类"
    }
    
    private var searchInfo = SearchInfo() {
        didSet {
            navigationItem.rightBarButtonItem?.isEnabled =
                !searchInfo.categories.isEmpty && (searchInfo.source == .EHentai || SettingManager.shared.isLoginSubject.value)
            if oldValue.keyWord == searchInfo.keyWord { tableView.reloadData() }
        }
    }
    
    private lazy var doubleTapCategoryGestureRecognizer = {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapCategoryHeaderAction))
        gestureRecognizer.numberOfTapsRequired = 2
        return gestureRecognizer
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
        SectionType.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SectionType.allCases[section] {
        case .keyword:
            return 1
        case .dateSource:
            return SearchInfo.Source.allCases.count
        case .language:
            return SearchInfo.Language.allCases.count
        case .rating:
            return SearchInfo.Rating.allCases.count
        case .category:
            return SearchInfo.Category.allCases.count
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionType = SectionType.allCases[section]
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: NSStringFromClass(UITableViewHeaderFooterView.self))
        header?.textLabel?.text = sectionType.rawValue
        if sectionType == .category {
            header?.removeGestureRecognizer(doubleTapCategoryGestureRecognizer)
            header?.addGestureRecognizer(doubleTapCategoryGestureRecognizer)
        }
        return header
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionType = SectionType.allCases[indexPath.section]
        let cls = sectionType == .keyword ? SearchTextFieldCell.self : UITableViewCell.self
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(cls), for: indexPath)
        cell.selectionStyle = .none
        
        switch sectionType {
        case .keyword:
            if let cell = cell as? SearchTextFieldCell {
                if cell.searchTextField.text?.isEmpty ?? true {
                    cell.searchTextField.text = searchInfo.keyWord
                }
                cell.textChangedAction = { [weak self] in
                    guard let self, searchInfo.keyWord != $0 else { return }
                    searchInfo.keyWord = $0
                }
            }
        case .dateSource:
            let source = SearchInfo.Source.allCases[indexPath.row]
            cell.textLabel?.text = source.searchItemTitle
            cell.accessoryType = (searchInfo.source == source) ? .checkmark : .none
        case .language:
            let language = SearchInfo.Language.allCases[indexPath.row]
            cell.textLabel?.text = language.searchItemTitle
            cell.accessoryType = (searchInfo.language == language) ? .checkmark : .none
        case .rating:
            let rating = SearchInfo.Rating.allCases[indexPath.row]
            cell.textLabel?.text = rating.searchItemTitle
            cell.accessoryType = (searchInfo.rating == rating) ? .checkmark : .none
        case .category:
            let category = SearchInfo.Category.allCases[indexPath.row]
            cell.textLabel?.text = category.searchItemTitle
            cell.accessoryType = searchInfo.categories.contains(category) ? .checkmark : .none
        }
        return cell
    }
}

// MARK: UITableViewDelegate
extension SearchViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch SectionType.allCases[indexPath.section] {
        case .keyword:
            break
        case .dateSource:
            searchInfo.source = SearchInfo.Source.allCases[indexPath.row]
        case .language:
            searchInfo.language = SearchInfo.Language.allCases[indexPath.row]
        case .rating:
            searchInfo.rating = SearchInfo.Rating.allCases[indexPath.row]
        case .category:
            let category = SearchInfo.Category.allCases[indexPath.row]
            if searchInfo.categories.contains(category) {
                searchInfo.categories.removeAll(where: { $0 == category })
            } else {
                searchInfo.categories.append(category)
            }
        }
    }
}
