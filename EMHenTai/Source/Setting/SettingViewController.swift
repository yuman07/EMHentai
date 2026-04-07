//
//  SettingViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Combine
import UIKit

final class SettingViewController: UITableViewController {
    private enum SectionType: CaseIterable {
        case loginState
        case dateSize
        case filter

        var title: String {
            switch self {
            case .loginState: return "setting.login_status".localized
            case .dateSize: return "setting.storage".localized
            case .filter: return "setting.filter".localized
            }
        }
    }

    private enum DataSizeType: CaseIterable {
        case history
        case download
        case other

        var title: String {
            switch self {
            case .history: return "setting.history_data".localized
            case .download: return "setting.download_data".localized
            case .other: return "setting.other_data".localized
            }
        }
    }

    private enum FilterType: CaseIterable {
        case ai
        case gore

        var title: String {
            switch self {
            case .ai: return "setting.ai_generated".localized
            case .gore: return "setting.gore".localized
            }
        }
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
        
        navigationItem.title = "tab.settings".localized
    }
    
    private func setupCombine() {
        SettingManager.shared.isLoginSubject
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] in
                guard let self, let index = SectionType.allCases.firstIndex(of: .loginState) else { return }
                tableView.reloadSections([index], with: .none)
                
                if $0 {
                    guard presentedViewController == nil else { return }
                    let vc = UIAlertController(title: "alert.notice".localized, message: "setting.login_success".localized, preferredStyle: .alert)
                    vc.addAction(UIAlertAction(title: "alert.ok".localized, style: .default))
                    UIApplication.shared.keyWindow?.rootViewController?.present(vc, animated: true)
                }
            }
            .store(in: &cancelBag)
    }
    
    private func reloadDataSize() {
        Task {
            guard let index = SectionType.allCases.firstIndex(of: .dateSize) else { return }
            dataSize = await SettingManager.shared.calculateUsedDiskSize()
            tableView.reloadSections([index], with: .none)
        }
    }
    
    private func login() {
        guard presentedViewController == nil else { return }
        let vc = UIAlertController(title: "setting.choose_login".localized, message: nil, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "setting.account_password".localized, style: .default, handler: { [weak self] _ in
            guard let self else { return }
            navigationController?.pushViewController(LoginViewController(), animated: true)
        }))
        vc.addAction(UIAlertAction(title: "Cookie", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            let alertVC = UIAlertController(title: "setting.login".localized, message: "setting.enter_cookie".localized, preferredStyle: .alert)
            alertVC.addTextField()
            alertVC.addAction(UIAlertAction(title: "setting.submit".localized, style: .default, handler: { [weak alertVC] _ in
                if let cookie = alertVC?.textFields?.first?.text, !cookie.isEmpty {
                    SettingManager.shared.loginWith(cookie: cookie)
                }
            }))
            alertVC.addAction(UIAlertAction(title: "alert.cancel".localized, style: .cancel))
            present(alertVC, animated: true)
        }))
        vc.addAction(UIAlertAction(title: "alert.cancel".localized, style: .cancel))
        present(vc, animated: true)
    }
    
    private func clearOtherData() {
        guard dataSize.otherSize > 0, presentedViewController == nil else { return }
        let vc = UIAlertController(title: "alert.notice".localized, message: "setting.clear_other_message".localized, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "alert.clear".localized, style: .default, handler: { [weak self] _ in
            guard let self else { return }
            Task {
                await SettingManager.shared.clearOtherData()
                self.reloadDataSize()
            }
        }))
        vc.addAction(UIAlertAction(title: "alert.cancel".localized, style: .cancel))
        present(vc, animated: true)
    }

    @objc func onFilterSwitchValueChanged(_ sender: UISwitch) {
        switch sender.tag {
        case 0:
            SettingManager.shared.isAIDisabled.toggle()
        case 1:
            SettingManager.shared.isGoreDisabled.toggle()
        default:
            break
        }
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
        case .filter:
            return FilterType.allCases.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        30
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        SectionType.allCases[section].title
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
        cell.selectionStyle = .default
        cell.accessoryView = nil
        
        switch SectionType.allCases[indexPath.section] {
        case .loginState:
            cell.textLabel?.text = SettingManager.shared.isLoginSubject.value ? "setting.logged_in".localized : "setting.not_logged_in".localized
        case .dateSize:
            let data = DataSizeType.allCases[indexPath.row]
            var text = data.title + ": "
            switch data {
            case .history:
                text += dataSize.historySize.diskSizeFormat
                cell.selectionStyle = .none
            case .download:
                text += dataSize.downloadSize.diskSizeFormat
                cell.selectionStyle = .none
            case .other:
                text += dataSize.otherSize.diskSizeFormat
            }
            cell.textLabel?.text = text
        case .filter:
            let switchView = UISwitch()
            switchView.tag = indexPath.row
            switchView.addTarget(self, action: #selector(onFilterSwitchValueChanged(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            let data = FilterType.allCases[indexPath.row]
            switch data {
            case .ai:
                switchView.isOn = SettingManager.shared.isAIDisabled
            case .gore:
                switchView.isOn = SettingManager.shared.isGoreDisabled
            }
            cell.textLabel?.text = data.title
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
        case .filter:
            guard let switchView = tableView.cellForRow(at: indexPath)?.accessoryView as? UISwitch else { return }
            switchView.setOn(!switchView.isOn, animated: true)
            onFilterSwitchValueChanged(switchView)
        }
    }
}
