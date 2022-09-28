//
//  GalleryCollectionViewCell.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/18.
//

import UIKit

final class GalleryCollectionViewCell: UICollectionViewCell {
    
    var tapBlock: (() -> Void)?
    
    private lazy var scrollView = {
        let view = UIScrollView()
        view.bounces = false
        view.bouncesZoom = false
        view.delegate = self
        view.maximumZoomScale = 3
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let imageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .black
        contentView.addSubview(scrollView)
        scrollView.addSubview(imageView)
        
        scrollView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        scrollView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        imageView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        imageView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
    }
    
    private func setupGesture() {
        let oneTap = UITapGestureRecognizer(target: self, action: #selector(oneTapAction))
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapAction))
        oneTap.require(toFail: doubleTap)
        doubleTap.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(oneTap)
        contentView.addGestureRecognizer(doubleTap)
    }
    
    @objc
    private func oneTapAction() {
        tapBlock?()
    }
    
    @objc
    private func doubleTapAction() {
        scrollView.setZoomScale(scrollView.zoomScale > 1 ? 1 : 2, animated: true)
    }
    
    func updateImageWith(filePath: String) {
        scrollView.setZoomScale(1, animated: false)
        imageView.image = UIImage(filePath: filePath)
    }
}

extension GalleryCollectionViewCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}
