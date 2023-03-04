//
//  GalleryViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Combine
import UIKit

final class GalleryViewController: UICollectionViewController {
    private let book: Book
    private var isRotating = false
    private var cancelBag = Set<AnyCancellable>()
    private var lastSeenPageIndex: Int {
        get { UserDefaults.standard.integer(forKey: "GalleryViewController_lastSeenPageIndex_\(book.gid)") }
        set { UserDefaults.standard.set(newValue, forKey: "GalleryViewController_lastSeenPageIndex_\(book.gid)") }
    }
    
    private let navBarBackgroundView = {
        let view = UIView()
        view.backgroundColor = .systemGroupedBackground
        view.translatesAutoresizingMaskIntoConstraints = false
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
        setupCombine()
        backToLastSeenPage()
        startDownload()
    }
    
    deinit {
        if !DBManager.shared.contains(gid: book.gid, of: .download) {
            DownloadManager.shared.suspend(book)
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
        
        NSLayoutConstraint.activate([
            navBarBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            navBarBackgroundView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            navBarBackgroundView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            navBarBackgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        ])
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "回到首页", style: .plain, target: self, action: #selector(backToFirstPage))
    }
    
    private func setupCombine() {
        DownloadManager.shared.downloadPageSuccessSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] obj in
                guard let self, obj.book.gid == self.book.gid else { return }
                self.collectionView.reloadItems(at: [IndexPath(row: obj.index, section: 0)])
            }
            .store(in: &cancelBag)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        isRotating = true
        let currentIndex = lastSeenPageIndex
        collectionView.collectionViewLayout.invalidateLayout()
        coordinator.animate(alongsideTransition: nil) { _ in
            self.isRotating = false
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.scrollToItem(at: IndexPath(row: currentIndex, section: 0), at: .left, animated: false)
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
        if book.downloadedImgCount == 0 {
            lastSeenPageIndex = 0
        } else if lastSeenPageIndex > 0 {
            let index = lastSeenPageIndex
            DispatchQueue.main.async { [weak self] in
                self?.collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .left, animated: false)
            }
        }
    }
    
    private func startDownload() {
        DownloadManager.shared.download(book)
        DBManager.shared.remove(book: book, of: .history)
        DBManager.shared.insert(book: book, of: .history)
    }
    
    @objc
    private func backToFirstPage() {
        collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: true)
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
        book.contentImgCount
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
        guard !isRotating else { return }
        navigationItem.title = "\(indexPath.row + 1)/\(book.contentImgCount)"
        lastSeenPageIndex = indexPath.row
    }
}
