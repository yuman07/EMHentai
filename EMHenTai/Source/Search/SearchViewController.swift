//
//  SearchViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/17.
//

import Foundation
import UIKit

class SearchViewController: UIViewController {
    private static let ratings = [
        "不限",
        "至少2星",
        "至少3星",
        "至少4星",
        "满星",
    ]
    private static let categorys = [
        "Doujinshi",
        "Manga",
        "Artist CG",
        "Game CG",
        "Western",
        "Non-H",
        "Image set",
        "Cosplay",
        "Asian Porn",
        "Misc",
    ]
    
    private var searchInfo = SearchInfo()
    
    weak var bookVC: BookListViewController?
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(searchAction))
        
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
        bookVC?.refreshData(with: searchInfo)
        navigationController?.popViewController(animated: true)
    }
}

extension SearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension SearchViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        case 2:
            return SearchSource.allCases.count
        case 3:
            return SearchViewController.ratings.count
        case 4:
            return SearchViewController.categorys.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "关键词"
        case 1:
            return "语言"
        case 2:
            return "数据源"
        case 3:
            return "星级"
        case 4:
            return "分类"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        30
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TextFieldTableViewCell.self), for: indexPath)
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
        }
        cell.selectionStyle = .none
        
        switch indexPath.section {
        case 0:
            if let cell = cell as? TextFieldTableViewCell {
                textField = cell.searchTextField
                textField?.text = searchInfo.keyWord
            }
        case 1:
            cell.textLabel?.text = "中文"
            cell.accessoryType = searchInfo.chineseOnly ? .checkmark : .none
        case 2:
            var text = SearchSource.allCases[indexPath.row].rawValue
            if (SearchSource.allCases[indexPath.row] == .ExHentai && !SettingManager.shared.isLogin) { text += "(登录后可用)" }
            cell.textLabel?.text = text
            cell.accessoryType = (searchInfo.source == SearchSource.allCases[indexPath.row].rawValue) ? .checkmark : .none
        case 3:
            cell.textLabel?.text = SearchViewController.ratings[indexPath.row]
            cell.accessoryType = (searchInfo.rating == indexPath.row) ? .checkmark : .none
        case 4:
            cell.textLabel?.text = SearchViewController.categorys[indexPath.row]
            var type = UITableViewCell.AccessoryType.none
            switch indexPath.row {
            case 0:
                type = searchInfo.doujinshi ? .checkmark : .none
            case 1:
                type = searchInfo.manga ? .checkmark : .none
            case 2:
                type = searchInfo.artistcg ? .checkmark : .none
            case 3:
                type = searchInfo.gamecg ? .checkmark : .none
            case 4:
                type = searchInfo.western ? .checkmark : .none
            case 5:
                type = searchInfo.non_h ? .checkmark : .none
            case 6:
                type = searchInfo.imageset ? .checkmark : .none
            case 7:
                type = searchInfo.cosplay ? .checkmark : .none
            case 8:
                type = searchInfo.asianporn ? .checkmark : .none
            case 9:
                type = searchInfo.misc ? .checkmark : .none
            default:
                break
            }
            cell.accessoryType = type
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
            searchInfo.chineseOnly = !searchInfo.chineseOnly
        case 2:
            searchInfo.source = SearchSource.allCases[indexPath.row].rawValue
        case 3:
            searchInfo.rating = indexPath.row
        case 4:
            switch indexPath.row {
            case 0:
                searchInfo.doujinshi = !searchInfo.doujinshi
            case 1:
                searchInfo.manga = !searchInfo.manga
            case 2:
                searchInfo.artistcg = !searchInfo.artistcg
            case 3:
                searchInfo.gamecg = !searchInfo.gamecg
            case 4:
                searchInfo.western = !searchInfo.western
            case 5:
                searchInfo.non_h = !searchInfo.non_h
            case 6:
                searchInfo.imageset = !searchInfo.imageset
            case 7:
                searchInfo.cosplay = !searchInfo.cosplay
            case 8:
                searchInfo.asianporn = !searchInfo.asianporn
            case 9:
                searchInfo.misc = !searchInfo.misc
            default:
                break
            }
        default:
            break
        }
        searchInfo.keyWord = textField?.text ?? ""
        tableView.reloadData()
    }
}
