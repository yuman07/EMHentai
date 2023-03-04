//
//  BookcaseViewModel.swift
//  EMHenTai
//
//  Created by yuman on 2022/10/1.
//

import Combine
import Foundation

final class BookcaseViewModel {
    @Published private(set) var books = [Book]()
    @Published private(set) var hint = BookcaseFooterView.HintType.empty
    @Published private(set) var isRefreshing = false
    
    private let type: BookcaseViewController.BookcaseType
    private var hasMore = true
    private var searchInfo = SearchInfo()
    private var cancelBag = Set<AnyCancellable>()
    
    init(type: BookcaseViewController.BookcaseType) {
        self.type = type
        setupCombine()
    }
    
    private func setupCombine() {
        if type == .home {
            SearchManager.shared.eventSubject
                .receive(on: DispatchQueue.main)
                .sink { [weak self] evnet in
                    guard let self else { return }
                    switch evnet {
                    case let .start(info: info):
                        self.onSearchStart(info: info)
                    case let .finish(info: info, result: result):
                        self.onSearchFinish(info: info, result: result)
                    }
                }
                .store(in: &cancelBag)
        } else {
            DBManager.shared.DBChangedSubject
                .receive(on: DispatchQueue.main)
                .sink { [weak self] type in
                    guard let self else { return }
                    switch (type, self.type) {
                    case (.history, .history):
                        fallthrough
                    case (.download, .download):
                        self.refreshData()
                    default:
                        break
                    }
                }
                .store(in: &cancelBag)
        }
    }
    
    private func onSearchStart(info: SearchInfo) {
        guard info.lastGid.isEmpty else { return }
        info.saveDB()
        isRefreshing = true
    }
    
    private func onSearchFinish(info: SearchInfo, result: Result<[Book], SearchManager.Error>) {
        searchInfo = info
        isRefreshing = false
        
        switch result {
        case .success(let newBooks):
            books = (info.lastGid.isEmpty ? newBooks : books + newBooks).unique()
            hasMore = !newBooks.isEmpty
            if hasMore { hint = .loading }
            else { hint = books.isEmpty ? .noData : .noMoreData }
        case .failure(let error):
            if (info.lastGid.isEmpty) { books = [] }
            switch error {
            case .netError:
                hint = .netError
            case .ipError:
                hint = .ipError
            }
        }
    }
    
    func refreshData() {
        switch type {
        case .home:
            searchInfo.lastGid = ""
            SearchManager.shared.searchWith(info: searchInfo)
        case .history, .download:
            books = (type == .history) ? DBManager.shared.books(of: .history) : DBManager.shared.books(of: .download)
            hint = books.isEmpty ? .noData : .noMoreData
        }
    }
    
    func loadMoreData() {
        guard type == .home, hasMore, case var nextInfo = searchInfo else { return }
        nextInfo.lastGid = books.last.flatMap { String($0.gid) } ?? ""
        SearchManager.shared.searchWith(info: nextInfo)
    }
}
