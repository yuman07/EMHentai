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
    private(set) var searchInfo = SearchInfo()
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
        guard info.pageIndex == 0 else { return }
        info.saveDB()
        isRefreshing = true
    }
    
    private func onSearchFinish(info: SearchInfo, result: Result<[Book], SearchManager.Error>) {
        searchInfo = info
        isRefreshing = false
        
        switch result {
        case .success(let newBooks):
            let preBooks = books
            books = (searchInfo.pageIndex == 0 ? newBooks : books + newBooks).unique()
            hasMore = (searchInfo.pageIndex == 0 ? !books.isEmpty : preBooks != books)
            if !hasMore { hint = books.isEmpty ? .noData : .noMoreData }
            else { hint = .loading }
        case .failure(let error):
            if (searchInfo.pageIndex == 0) { books = [] }
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
            searchInfo.pageIndex = 0
            SearchManager.shared.searchWith(info: searchInfo)
        case .history, .download:
            books = (type == .history) ? DBManager.shared.books(of: .history) : DBManager.shared.books(of: .download)
            hint = books.isEmpty ? .noData : .noMoreData
        }
    }
    
    func loadMoreData() {
        guard type == .home, hasMore, case var nextInfo = searchInfo else { return }
        nextInfo.pageIndex += 1
        SearchManager.shared.searchWith(info: nextInfo)
    }
}
