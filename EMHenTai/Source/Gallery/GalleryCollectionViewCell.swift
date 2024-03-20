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
    
    private let progressView = {
        let view = UIProgressView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 1
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
        imageView.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            progressView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 25),
            progressView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -25),
            progressView.heightAnchor.constraint(equalToConstant: 2),
            progressView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
        ])
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
        progressView.isHidden = imageView.image != nil
    }
    
    func updateProgress(_ progress: Progress) {
        progressView.progress = Float(progress.fractionCompleted)
    }
}

extension GalleryCollectionViewCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}
