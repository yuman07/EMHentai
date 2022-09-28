//
//  SettingViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import UIKit

final class SettingViewController: UITableViewController {
    private var dataSize = (historySize: 0, downloadSize: 0, otherSize: 0)
    private var token: NSObjectProtocol?
    private weak var cookieTextField: UITextField?
    
    init() {
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        token.flatMap { NotificationCenter.default.removeObserver($0) }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotification()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadDataSize()
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
        token = NotificationCenter.default.addObserver(forName: SettingManager.LoginStateChangedNotification,
                                                       object: nil,
                                                       queue: .main) { [weak self] _ in
            guard let self else { return }
            self.tableView.reloadSections([0], with: .none)
            
            if SettingManager.shared.isLogin {
                let vc = UIAlertController(title: "提示", message: "登录成功", preferredStyle: .alert)
                vc.addAction(UIAlertAction(title: "好的", style: .default))
                UIApplication.shared.keyWindow?.rootViewController?.present(vc, animated: true)
            }
        }
    }
    
    private func reloadDataSize() {
        Task {
            dataSize = await SettingManager.shared.calculateFileSize()
            tableView.reloadSections([1], with: .none)
        }
    }
    
    private func login() {
        let vc = UIAlertController(title: "请选择登录方式", message: nil, preferredStyle: .actionSheet)
        vc.addAction(UIAlertAction(title: "账号密码", style: .default, handler: { _ in
            self.navigationController?.pushViewController(LoginViewController(), animated: true)
        }))
        vc.addAction(UIAlertAction(title: "Cookie", style: .default, handler: { _ in
            let alertVC = UIAlertController(title: "登录", message: "请在此输入Cookie", preferredStyle: .alert)
            alertVC.addTextField { self.cookieTextField = $0 }
            alertVC.addAction(UIAlertAction(title: "提交", style: .default, handler: { _ in
                SettingManager.shared.loginWith(cookie: self.cookieTextField?.text ?? "")
            }))
            alertVC.addAction(UIAlertAction(title: "取消", style: .cancel))
            self.present(alertVC, animated: true)
        }))
        vc.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(vc, animated: true)
    }
    
    private func clearOtherData() {
        guard dataSize.otherSize > 0 else { return }
        let vc = UIAlertController(title: "提示", message: "确定要清除其他数据吗？\n（包含如封面图等数据）", preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "清除", style: .default, handler: { _ in
            Task {
                await SettingManager.shared.clearOtherData()
                self.reloadDataSize()
            }
        }))
        vc.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(vc, animated: true)
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
            return 3
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
            let text: String
            switch indexPath.row {
            case 0:
                text = "历史数据：" + dataSize.historySize.diskSizeFormat
            case 1:
                text = "下载数据：" + dataSize.downloadSize.diskSizeFormat
            case 2:
                text = "其它数据：" + dataSize.otherSize.diskSizeFormat
            default:
                text = ""
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
                login()
            }
        case 1:
            if indexPath.row == 2 {
                clearOtherData()
            }
        default:
            break
        }
    }
}
