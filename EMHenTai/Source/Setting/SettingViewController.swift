//
//  SettingViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import UIKit

class SettingViewController: UIViewController {
    
    var downloadSize: Int?
    var historySize: Int?
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: CGRect.zero, style: .grouped)
        table.estimatedRowHeight = 0
        table.estimatedSectionHeaderHeight = 0
        table.estimatedSectionFooterHeight = 0
        table.bounces = false
        table.rowHeight = 44
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        SettingManager.shared.calculateFilesSize { [weak self] (downloadSize: Int, historySize: Int) in
            self?.downloadSize = downloadSize
            self?.historySize = historySize
            self?.tableView.reloadData()
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(tableView)
        
        navigationItem.title = "设置"
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }
    
    private func setupNotification() {
        NotificationCenter.default.addObserver(forName: SettingManager.LoginStateChangedNotification,
                                               object: nil,
                                               queue: .main) { [weak self] _ in
            self?.tableView.reloadData()
        }
    }
}

extension SettingViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return UserLanguage.allCases.count
        case 2:
            return 2
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        30
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "登录状态"
        case 1:
            return "界面语言(重启生效)"
        case 2:
            return "磁盘占用"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
        cell.accessoryType = .none
        cell.selectionStyle = .default
        
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = SettingManager.shared.isLogin ? "已登录：点击可登出" : "未登录：点击去登录"
            return cell
        case 1:
            cell.textLabel?.text = UserLanguage.allCases[indexPath.row].rawValue
            cell.accessoryType = (SettingManager.shared.currentLanguage == UserLanguage.allCases[indexPath.row]) ? .checkmark : .none
            return cell
        case 2:
            cell.selectionStyle = .none
            var text = indexPath.row == 0 ? "下载数据" : "历史数据"
            if let size = (indexPath.row == 0 ? self.downloadSize : self.historySize) {
                text += "：\(size.diskSizeFormat)"
            }
            cell.textLabel?.text = text
            return cell
        default:
            return cell
        }
    }
}

extension SettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            if SettingManager.shared.isLogin {
                SettingManager.shared.logout()
            } else {
                navigationController?.pushViewController(LoginViewController(), animated: true)
            }
        case 1:
            SettingManager.shared.currentLanguage = UserLanguage.allCases[indexPath.row]
            tableView.reloadData()
            break
        case 2:
            break
        default:
            break
        }
    }
}
