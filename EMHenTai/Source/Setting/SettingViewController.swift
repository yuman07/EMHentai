//
//  SettingViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Combine
import UIKit

final class SettingViewController: UITableViewController {
    private enum SectionType: String, CaseIterable {
        case loginState = "登录状态"
        case dateSize = "存储占用"
    }
    
    private enum DataSizeType: String, CaseIterable {
        case history = "历史数据"
        case download = "下载数据"
        case other = "其它数据"
    }
    
    private var dataSize = (historySize: 0, downloadSize: 0, otherSize: 0)
    private var cancelBag = Set<AnyCancellable>()
    
    init() {
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCombine()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadDataSize()
    }
    
    private func setupUI() {
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = 44
        tableView.bounces = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        
        navigationItem.title = "设置"
    }
    
    private func setupCombine() {
        SettingManager.shared.isLoginSubject
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] isLogin in
                guard let self, let index = SectionType.allCases.firstIndex(of: .loginState) else { return }
                self.tableView.reloadSections([index], with: .none)
                
                if isLogin {
                    guard self.presentedViewController == nil else { return }
                    let vc = UIAlertController(title: "提示", message: "登录成功", preferredStyle: .alert)
                    vc.addAction(UIAlertAction(title: "好的", style: .default))
                    UIApplication.shared.keyWindow?.rootViewController?.present(vc, animated: true)
                }
            }
            .store(in: &cancelBag)
    }
    
    private func reloadDataSize() {
        Task {
            guard let index = SectionType.allCases.firstIndex(of: .dateSize) else { return }
            dataSize = await SettingManager.shared.calculateFileSize()
            tableView.reloadSections([index], with: .none)
        }
    }
    
    private func login() {
        guard presentedViewController == nil else { return }
        let vc = UIAlertController(title: "请选择登录方式", message: nil, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "账号密码", style: .default, handler: { _ in
            self.navigationController?.pushViewController(LoginViewController(), animated: true)
        }))
        vc.addAction(UIAlertAction(title: "Cookie", style: .default, handler: { _ in
            let alertVC = UIAlertController(title: "登录", message: "请在此输入Cookie", preferredStyle: .alert)
            alertVC.addTextField()
            alertVC.addAction(UIAlertAction(title: "提交", style: .default, handler: { [weak alertVC] _ in
                if let cookie = alertVC?.textFields?.first?.text, !cookie.isEmpty {
                    SettingManager.shared.loginWith(cookie: cookie)
                }
            }))
            alertVC.addAction(UIAlertAction(title: "取消", style: .cancel))
            self.present(alertVC, animated: true)
        }))
        vc.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(vc, animated: true)
    }
    
    private func clearOtherData() {
        guard dataSize.otherSize > 0, presentedViewController == nil else { return }
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
        SectionType.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SectionType.allCases[section] {
        case .loginState:
            return 1
        case .dateSize:
            return DataSizeType.allCases.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        30
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        SectionType.allCases[section].rawValue
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
        
        switch SectionType.allCases[indexPath.section] {
        case .loginState:
            cell.textLabel?.text = SettingManager.shared.isLoginSubject.value ? "已登录：点击可登出" : "未登录：点击去登录"
            cell.selectionStyle = .default
        case .dateSize:
            let data = DataSizeType.allCases[indexPath.row]
            var text = "\(data.rawValue)："
            switch data {
            case .history:
                text += dataSize.historySize.diskSizeFormat
            case .download:
                text += dataSize.downloadSize.diskSizeFormat
            case .other:
                text += dataSize.otherSize.diskSizeFormat
            }
            cell.textLabel?.text = text
            cell.selectionStyle = .none
        }
        
        return cell
    }
}

// MARK: UITableViewDelegate
extension SettingViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch SectionType.allCases[indexPath.section] {
        case .loginState:
            if SettingManager.shared.isLoginSubject.value {
                SettingManager.shared.logout()
            } else {
                SettingManager.shared.logout()
                login()
            }
        case .dateSize:
            if DataSizeType.allCases[indexPath.row] == .other {
                clearOtherData()
            }
        }
    }
}
