//
//  GalleryViewController.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/14.
//

import Foundation
import UIKit

class GalleryViewController: UIViewController {
    private var book: Book!
    
    private let navBarBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let view = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        view.delegate = self
        view.dataSource = self
        view.isPagingEnabled = true
        view.backgroundColor = .black
        view.contentInsetAdjustmentBehavior = .never
        view.register(PageCollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(PageCollectionViewCell.self))
        return view
    }()
    
    init(book: Book) {
        self.book = book
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNotification()
        DownloadManager.shared.download(book: self.book)
    }
    
    private func setupView() {
        view.backgroundColor = .black
        view.addSubview(collectionView)
        view.addSubview(navBarBackgroundView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        collectionView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        navBarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        navBarBackgroundView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        navBarBackgroundView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        navBarBackgroundView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        navBarBackgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    }
    
    private func setupNotification() {
        NotificationCenter.default.addObserver(forName: DownloadManager.DownloadPageSuccessNotification,
                                               object: nil,
                                               queue: .main) { notification in
            if let obj = notification.object, let gid = obj as? Int, gid == self.book.gid {
                self.collectionView.reloadData()
            }
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
}

extension GalleryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        Int(self.book.filecount) ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(PageCollectionViewCell.self), for: indexPath)
        if let cell = cell as? PageCollectionViewCell {
            cell.updateImageWith(filePath: book.imagePath(at: indexPath.row))
        }
        return cell
    }
}

extension GalleryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        changeNavBarHidden()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        navigationItem.title = "\(indexPath.row + 1)/\(self.book.filecount)"
    }
}
