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
    
    fileprivate var titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.numberOfLines = 0
        return lbl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUIElements()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func configureCell(someCellModel: ExampleCellModel) {
        titleLabel.text = someCellModel.urlString
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        progressView.progress = 0
        progressLabel.text = ""
    }
    
    open func setupUIElements() {
        addSubview(containerView)
        
        [titleLabel, progressLabel, progressView].forEach { (subview) in
            containerView.addSubview(subview)
        }
        
        // Handle layout...
        
        let padding: CGFloat = 12.0
        
        containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding).isActive = true
        containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding).isActive = true
        containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding).isActive = true
        containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding).isActive = true
        
        titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -padding).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: progressLabel.topAnchor, constant: -padding).isActive = true
        
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
//        v.isMuted = true
        return v
    }()
    
    private lazy var playButton: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Play", for: .normal)
        btn.backgroundColor = UIColor.white
        btn.clipsToBounds = true
        btn.layer.cornerRadius = 10
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        btn.setTitleColor(UIColor.blue, for: UIControl.State.normal)
        btn.addTarget(self, action: #selector(togglePlaying), for: UIControl.Event.touchUpInside)
        return btn
    }()
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playerView.reset()
    }
    
    override func setupUIElements() {
        super.setupUIElements()
        
        [playerView, playButton].forEach { (subview) in
            containerView.addSubview(subview)
        }
        
        let padding: CGFloat = 12
        
        // Handle layout...
        playerView.leadingAnchor.constraint(equalTo: super.containerView.leadingAnchor, constant: padding).isActive = true
        playerView.topAnchor.constraint(equalTo: super.containerView.topAnchor, constant: padding).isActive = true
        playerView.trailingAnchor.constraint(equalTo: super.containerView.trailingAnchor, constant: -padding).isActive = true
        playerView.bottomAnchor.constraint(equalTo: super.titleLabel.topAnchor, constant: -padding).isActive = true
        
        playButton.trailingAnchor.constraint(equalTo: playerView.trailingAnchor, constant: -padding).isActive = true
        playButton.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -padding).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        
    }
    
    @objc private func togglePlaying() {
        let shouldBeginPlaying: Bool = playerView.isPlaying == false
        shouldBeginPlaying ? playerView.play() : playerView.pause()
        if shouldBeginPlaying {
            playerView.loop(didReachEnd: {
                print("Did reach end, looping")
            })
        } else {
            playerView.stopLooping()
        }
        let newPlayButtonTitle = shouldBeginPlaying ? "Play" : "Pause"
        playButton.setTitle(newPlayButtonTitle, for: UIControl.State.normal)
    }
    
    private weak var playtimeObserver: NSObjectProtocol?

    // This function is called during the cell dequeue process and will load the image
    // using the `CellModel` struct. However, this would be replaced with your method.
    public override func configureCell(someCellModel: ExampleCellModel) {
        super.configureCell(someCellModel: someCellModel)
        print("------------------\nstarting new video\n------------------")
        let urlString = someCellModel.urlString
        playerView.loadVideoFrom(urlString: urlString)
        playerView.generateThumbnailImage(shouldCacheInMemory: true, completion: { (image) in
            print("Generated thumbnail image: \(String(describing: image))")
        })
        
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
        
    }
}

extension VideoCell: URLVideoPlayerViewDelegate {
    
    func urlVideoPlayerIsReadyToPlay(_ view: URLVideoPlayerView) {

    }
    
    func urlCachableView(_ view: URLCachableView, didFinishDownloading media: Any) {
        super.updateCompletion()
    }
   
    func urlCachableView(_ view: URLCachableView, downloadFailedWith error: Error) {
        super.updateError()
    }
   
    func urlCachableView(_ view: URLCachableView, downloadProgress progress: Float, humanReadableProgress: String) {
        super.updateProgress(progress, humanReadableProgress: humanReadableProgress)
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
        imageView.bottomAnchor.constraint(equalTo: super.titleLabel.topAnchor, constant: -padding).isActive = true
    }
    
    // This function is called during the cell dequeue process and will load the image
    // using the `CellModel` struct. However, this would be replaced with your method.
    public override func configureCell(someCellModel: ExampleCellModel) {
        super.configureCell(someCellModel: someCellModel)
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
