//
//  SettingViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import UIKit

class SettingViewController: UIViewController {
    private var fileSize: (download: Int, history: Int)?
    
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
            guard let self = self else { return }
            self.fileSize = (downloadSize, historySize)
            self.tableView.reloadSections([1], with: .none)
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
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

extension SettingViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
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
            return "存储占用"
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

extension SettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            if SettingManager.shared.isLogin {
                SettingManager.shared.logout()
            } else {
                SettingManager.shared.logout()
                navigationController?.pushViewController(WebViewController(url: SettingManager.shared.loginURL, needSyncCookieToApp: true), animated: true)
            }
        case 1:
            break
        default:
            break
        }
    }
}
