//
//  BookcaseViewModel.swift
//  EMHenTai
//
//  Created by yuman on 2022/10/1.
//

import Foundation
import Combine

final class BookcaseViewModel {
    let type: BookcaseViewController.BookcaseType
    
    @Published var books = [Book]()
    @Published var hint = BookcaseFooterView.HintType.empty
    @Published var isRefreshing = false
    
    private var hasMore = true
    private var searchInfo = SearchInfo()
    
    init(type: BookcaseViewController.BookcaseType) {
        self.type = type
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

extension BookcaseViewModel: SearchManagerCallbackDelegate {
    func searchStartCallback(searchInfo: SearchInfo) {
        guard searchInfo.pageIndex == 0 else { return }
        searchInfo.saveDB()
        isRefreshing = true

    }
    
    func searchFinishCallback(searchInfo: SearchInfo, result: Result<[Book], SearchManager.SearchError>) {
        switch result {
        case .success(let newBooks):
            hasMore = !newBooks.isEmpty
            books = (searchInfo.pageIndex == 0 ? newBooks : books + newBooks).unique()
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
        
        isRefreshing = false
        self.searchInfo = searchInfo
    }
}
