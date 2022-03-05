//
//  SettingViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import UIKit

final class SettingViewController: UITableViewController {
    private var fileSize: (download: Int, history: Int)?
    
    init() {
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        SettingManager.shared.calculateFilesSize { [weak self] (downloadSize, historySize) in
            guard let self = self else { return }
            self.fileSize = (downloadSize, historySize)
            self.tableView.reloadSections([1], with: .none)
        }
    }
    
    private func setupUI() {
        tableView.backgroundColor = .systemGroupedBackground
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.bounces = false
        tableView.rowHeight = 44
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        
        navigationItem.title = "设置"
    }
    
    private func setupNotification() {
        var token: NSObjectProtocol?
        token = NotificationCenter.default.addObserver(forName: SettingManager.LoginStateChangedNotification,
                                                       object: nil,
                                                       queue: .main) { [weak self] _ in
            guard let self = self else { NotificationCenter.default.removeObserver(token!); return }
            self.tableView.reloadSections([0], with: .none)
        }
    }
}

// MARK: UITableViewDataSource
extension SettingViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 2
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        30
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "登录状态"
        case 1:
            return "存储占用"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
        
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = SettingManager.shared.isLogin ? "已登录：点击可登出" : "未登录：点击去登录"
            cell.selectionStyle = .default
        case 1:
            var text = indexPath.row == 0 ? "下载数据" : "历史数据"
            if let size = (indexPath.row == 0 ? self.fileSize?.download : self.fileSize?.history) {
                text += "：\(size.diskSizeFormat)"
            }
            cell.textLabel?.text = text
            cell.selectionStyle = .none
        default:
            break
        }
        
        return cell
    }
}

// MARK: UITableViewDelegate
extension SettingViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            if SettingManager.shared.isLogin {
                SettingManager.shared.logout()
            } else {
                SettingManager.shared.logout()
                navigationController?.pushViewController(LoginViewController(), animated: true)
            }
        case 1:
            break
        default:
            break
        }
    }
}
