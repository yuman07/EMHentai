//
//  SearchViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/17.
//

import Foundation
import UIKit

protocol searchVCItemProtocol {
    var searchItemTitle: String { get }
}

class SearchViewController: UIViewController {
    private static let sections = [
        "关键词",
        "数据源",
        "语言",
        "评分",
        "分类",
    ]
    
    private var searchInfo = SearchInfo()
    
    weak var textField: UITextField?
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: CGRect.zero, style: .grouped)
        table.rowHeight = 44
        table.estimatedRowHeight = 0
        table.estimatedSectionHeaderHeight = 0
        table.estimatedSectionFooterHeight = 0
        table.delegate = self
        table.dataSource = self
        table.bounces = false
        table.register(TextFieldTableViewCell.self, forCellReuseIdentifier: NSStringFromClass(TextFieldTableViewCell.self))
        table.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        return table
    }()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
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
        
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }
    
    @objc
    private func searchAction() {
        searchInfo.keyWord = textField?.text ?? ""
        SearchManager.shared.searchWith(info: searchInfo)
        navigationController?.popViewController(animated: true)
    }
}

extension SearchViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        SearchViewController.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
            return SearchInfo.Catetory.allCases.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        SearchViewController.sections[section]
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        30
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cls = indexPath.section == 0 ? TextFieldTableViewCell.self : UITableViewCell.self
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(cls), for: indexPath)
        cell.selectionStyle = .none
        
        switch indexPath.section {
        case 0:
            if let cell = cell as? TextFieldTableViewCell {
                textField = cell.searchTextField
                textField?.text = searchInfo.keyWord
            }
        case 1:
            let source = SearchInfo.Source.allCases[indexPath.row]
            var text = source.searchItemTitle
            if (source == .ExHentai && !SettingManager.shared.isLogin) { text += "(登录后可用)" }
            cell.textLabel?.text = text
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
            let category = SearchInfo.Catetory.allCases[indexPath.row]
            cell.textLabel?.text = category.searchItemTitle
            cell.accessoryType = searchInfo.catetories.contains(category) ? .checkmark : .none
        default:
            break
        }
        return cell
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
            let category = SearchInfo.Catetory.allCases[indexPath.row]
            if searchInfo.catetories.contains(category) {
                searchInfo.catetories.removeAll(where: { $0 == category })
            } else {
                searchInfo.catetories.append(category)
            }
        default:
            break
        }
        searchInfo.keyWord = textField?.text ?? ""
        tableView.reloadSections([indexPath.section], with: .none)
    }
}
