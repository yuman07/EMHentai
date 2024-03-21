//
//  BookListViewModel.swift
//  EMHenTai
//
//  Created by yuman on 2022/10/1.
//

import Combine
import Foundation

final class BookListViewModel {
    @Published private(set) var books = [Book]()
    @Published private(set) var hint = BookListFooterView.HintType.empty
    @Published private(set) var isRefreshing = false
    
    private let type: BookListViewController.BookListType
    private var hasMore = true
    private var searchInfo = SearchInfo()
    private var cancelBag = Set<AnyCancellable>()
    
    init(type: BookListViewController.BookListType) {
        self.type = type
        setupCombine()
    }
    
    private func setupCombine() {
        if type == .home {
            SearchManager.shared.eventSubject
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    guard let self else { return }
                    switch $0 {
                    case let .start(info: info):
                        onSearchStart(info: info)
                    case let .finish(info: info, result: result):
                        onSearchFinish(info: info, result: result)
                    }
                }
                .store(in: &cancelBag)
        } else {
            DBManager.shared.DBChangedSubject
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    guard let self else { return }
                    switch ($0, type) {
                    case (.history, .history), (.download, .download):
                        refreshData()
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
