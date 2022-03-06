//
//  GalleryViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import UIKit

final class GalleryViewController: UICollectionViewController {
    private let book: Book
    private var isRotating = false
    private var lastSeenPageIndex: Int {
        get { UserDefaults.standard.integer(forKey: "GalleryViewController_lastSeenPageIndex_\(book.gid)") }
        set { UserDefaults.standard.set(newValue, forKey: "GalleryViewController_lastSeenPageIndex_\(book.gid)") }
    }
    
    private let navBarBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGroupedBackground
        return view
    }()
    
    init(book: Book) {
        self.book = book
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        super.init(collectionViewLayout: layout)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotification()
        backToLastSeenPage()
        DownloadManager.shared.download(book: book)
        DBManager.shared.remove(book: book, of: .history)
        DBManager.shared.insert(book: book, of: .history)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !DBManager.shared.contains(gid: book.gid, of: .download) {
            DownloadManager.shared.suspend(book: book)
        }
    }
    
    private func setupUI() {
        collectionView.addSubview(navBarBackgroundView)
        collectionView.backgroundColor = .black
        collectionView.isPagingEnabled = true
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(GalleryCollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(GalleryCollectionViewCell.self))
        
        navBarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        navBarBackgroundView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        navBarBackgroundView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        navBarBackgroundView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        navBarBackgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "回到首页", style: .plain, target: self, action: #selector(backToFirstPage))
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        isRotating = true
        let currentIndex = Int(collectionView.contentOffset.x / collectionView.bounds.size.width)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.isRotating = false
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.scrollToItem(at: IndexPath(row: currentIndex, section: 0), at: .left, animated: false)
        }
    }
    
    private func setupNotification() {
        var token: NSObjectProtocol?
        token = NotificationCenter.default.addObserver(forName: DownloadManager.DownloadPageSuccessNotification,
                                                       object: nil,
                                                       queue: .main) { [weak self] notification in
            guard let self = self else { NotificationCenter.default.removeObserver(token!); return }
            guard let (gid, index) = notification.object as? (Int, Int), gid == self.book.gid else { return }
            self.collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        let isHide = navigationController?.navigationBar.isHidden ?? false
        return isHide ? .lightContent : .darkContent
    }
    
    private func changeNavBarHidden() {
        let isHide = navigationController?.navigationBar.isHidden ?? false
        navigationController?.setNavigationBarHidden(!isHide, animated: false)
        navBarBackgroundView.isHidden = !isHide
        setNeedsStatusBarAppearanceUpdate()
    }
    
    private func backToLastSeenPage() {
        if book.downloadedFileCount == 0 {
            self.lastSeenPageIndex = 0
        } else {
            let index = self.lastSeenPageIndex
            guard index > 0 else { return }
            DispatchQueue.main.async {
                self.collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .left, animated: false)
            }
        }
    }
    
    @objc
    private func backToFirstPage() {
        if !collectionView.visibleCells.isEmpty {
            collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: true)
        }
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension GalleryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        isRotating ? .zero : collectionView.bounds.size
    }
}

// MARK: UICollectionViewDataSource
extension GalleryViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        book.fileCountNum
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(GalleryCollectionViewCell.self), for: indexPath)
        if let cell = cell as? GalleryCollectionViewCell {
            cell.updateImageWith(filePath: book.imagePath(at: indexPath.row))
            cell.tapBlock = { [weak self] in
                self?.changeNavBarHidden()
            }
        }
        return cell
    }
}

// MARK: UICollectionViewDelegate
extension GalleryViewController {
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        navigationItem.title = "\(indexPath.row + 1)/\(book.fileCountNum)"
        lastSeenPageIndex = indexPath.row
    }
}
