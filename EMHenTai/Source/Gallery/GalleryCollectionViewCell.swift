//
//  GalleryCollectionViewCell.swift
//  EMHenTai
//
//  Created by yuman on 2022/1/18.
//

import Foundation
import UIKit

class GalleryCollectionViewCell: UICollectionViewCell {
    
    var tapBlock: (() -> Void)?
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.bounces = false
        view.bouncesZoom = false
        view.delegate = self
        view.maximumZoomScale = 3
        return view
    }()
    
    private let imageView: UIImageView = {
        let img = UIImageView()
        img.contentMode = .scaleAspectFit
        return img
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
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        scrollView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        imageView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
    }
    
    private func setupGesture() {
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapAction)))
    }
    
    @objc
    private func tapAction() {
        tapBlock?()
    }
    
    func updateImageWith(filePath: String) {
        if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
            imageView.image = UIImage(data: data)
        } else {
            imageView.image = nil
        }
    }
}

extension GalleryCollectionViewCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}
