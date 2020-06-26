//
//  ExampleCells.swift
//  Celestial
//
//  Created by Chrishon Wyllie on 1/2/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import Celestial
import AVFoundation

class ExampleCell: UICollectionViewCell {
    
    public var containerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 10
        v.clipsToBounds = true
        return v
    }()
    
    fileprivate var progressLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    fileprivate var progressView: UIProgressView = {
        let v = UIProgressView(progressViewStyle: .default)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.progressTintColor = UIColor.red
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUIElements()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func configureCell(someCellModel: ExampleCellModel) {}
    
    open func setupUIElements() {
        addSubview(containerView)
        
        [progressLabel, progressView].forEach { (subview) in
            containerView.addSubview(subview)
        }
        
        // Handle layout...
        
        let padding: CGFloat = 12.0
        
        containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding).isActive = true
        containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding).isActive = true
        containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding).isActive = true
        containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding).isActive = true
        
        progressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding).isActive = true
        progressLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -padding).isActive = true
        progressLabel.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -padding).isActive = true
        progressLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding).isActive = true
        progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -padding).isActive = true
        progressView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -padding).isActive = true
    }
    
    func updateCompletion() {
        DispatchQueue.main.async {
            self.progressLabel.text = "Finished Downloadin'!"
        }
    }

    func updateProgress(_ progress: Float, humanReadableProgress: String) {
        DispatchQueue.main.async {
            self.progressView.progress = Float(progress)
            self.progressLabel.text = humanReadableProgress
        }
    }
    
    func updateError() {
        DispatchQueue.main.async {
            self.progressLabel.text = "Error downloading!"
            self.progressLabel.textColor = .red
        }
    }
}













// MARK: - VideoCell

class VideoCell: ExampleCell {
    
    public lazy var playerView: URLVideoPlayerView = {
        let v = URLVideoPlayerView(delegate: self, cacheLocation: .fileSystem)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        return v
    }()
    
    
    
    
    
    
    override func setupUIElements() {
        super.setupUIElements()
        
        [playerView].forEach { (subview) in
            containerView.addSubview(subview)
        }
        
        let padding: CGFloat = 12
        
        // Handle layout...
        playerView.leadingAnchor.constraint(equalTo: super.containerView.leadingAnchor, constant: padding).isActive = true
        playerView.topAnchor.constraint(equalTo: super.containerView.topAnchor, constant: padding).isActive = true
        playerView.trailingAnchor.constraint(equalTo: super.containerView.trailingAnchor, constant: -padding).isActive = true
        playerView.bottomAnchor.constraint(equalTo: super.progressLabel.topAnchor, constant: -padding).isActive = true
        
    }
    
    
    private weak var playtimeObserver: NSObjectProtocol?

    // This function is called during the cell dequeue process and will load the image
    // using the `CellModel` struct. However, this would be replaced with your method.
    public override func configureCell(someCellModel: ExampleCellModel) {
        print("------------------\nstarting new video\n------------------")
        let urlString = someCellModel.urlString
        playerView.loadVideoFrom(urlString: urlString)
        
//        playerView.loadVideoFrom(urlString: someCellModel.urlString, progressHandler: { (progress) in
//            print("current downlod progress: \(progress)")
//            self.updateProgress(progress, humanReadableProgress: "Not sure")
//        }, completion: {
//            print("Image has finished loading")
//            self.updateCompletion()
//        }) { (error) in
//            print("Error loading image")
//            self.updateError()
//        }
        
        if playtimeObserver != nil {
            NotificationCenter.default.removeObserver(playtimeObserver!)
            playtimeObserver = nil
        }
     
    }
    
    private func observeDidPlayToEndTime() {
        
        let playerItem = (playerView.player?.currentItem)!
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                                  object: playerItem,
                                                                  queue: .main,
                                                                  using: { [weak self] (notification) in
            guard let strongSelf = self else { return }
            strongSelf.playerView.player?.seek(to: CMTime.zero)
            strongSelf.playerView.player?.play()
        })
    }
    
    
}

extension VideoCell: URLVideoPlayerViewDelegate {
    
    func urlVideoPlayerIsReadyToPlay(_ view: URLVideoPlayerView) {
        view.player?.play()
        observeDidPlayToEndTime()
    }
    
    func urlCachableView(_ view: URLCachableView, didFinishDownloading media: Any) {
        updateCompletion()
    }
   
    func urlCachableView(_ view: URLCachableView, downloadFailedWith error: Error) {
        updateError()
    }
   
    func urlCachableView(_ view: URLCachableView, downloadProgress progress: Float, humanReadableProgress: String) {
        updateProgress(progress, humanReadableProgress: humanReadableProgress)
    }
    
}

























// MARK: - ImageCell

class ImageCell: ExampleCell {

    // Initialize the URLImageView within the cell as a variable.
    // NOTE: The second initializer is used which does NOT have the urlString argument.
    private lazy var imageView: URLImageView = {
        let img = URLImageView(delegate: self, cacheLocation: .inMemory)
        img.translatesAutoresizingMaskIntoConstraints = false
        img.backgroundColor = .gray
        img.contentMode = .scaleAspectFill
        img.clipsToBounds = true
        return img
    }()
    
    
    
    override func setupUIElements() {
        super.setupUIElements()
        
        [imageView].forEach { (subview) in
            containerView.addSubview(subview)
        }
        
        let padding: CGFloat = 12
        
        // Handle layout...
        imageView.leadingAnchor.constraint(equalTo: super.containerView.leadingAnchor, constant: padding).isActive = true
        imageView.topAnchor.constraint(equalTo: super.containerView.topAnchor, constant: padding).isActive = true
        imageView.trailingAnchor.constraint(equalTo: super.containerView.trailingAnchor, constant: -padding).isActive = true
        imageView.bottomAnchor.constraint(equalTo: super.progressLabel.topAnchor, constant: -padding).isActive = true
    }
    
    // This function is called during the cell dequeue process and will load the image
    // using the `CellModel` struct. However, this would be replaced with your method.
    public override func configureCell(someCellModel: ExampleCellModel) {
//        imageView.loadImageFrom(urlString: someCellModel.urlString)
        
        imageView.loadImageFrom(urlString: someCellModel.urlString, progressHandler: { (progress) in
            print("current downlod progress: \(progress)")
            self.updateProgress(progress, humanReadableProgress: "Not sure")
        }, completion: {
            print("Image has finished loading")
            self.updateCompletion()
        }) { (error) in
            print("Error loading image")
            self.updateError()
        }
    }
    
}

extension ImageCell: URLCachableViewDelegate {
    
    func urlCachableView(_ view: URLCachableView, didFinishDownloading media: Any) {
        updateCompletion()
    }
    
    func urlCachableView(_ view: URLCachableView, downloadFailedWith error: Error) {
        updateError()
    }
    
    func urlCachableView(_ view: URLCachableView, downloadProgress progress: Float, humanReadableProgress: String) {
        updateProgress(progress, humanReadableProgress: humanReadableProgress)
    }
}
