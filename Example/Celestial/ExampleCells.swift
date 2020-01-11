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
        
        // Handle layout...
        containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        containerView.topAnchor.constraint(equalTo: topAnchor, constant: 12).isActive = true
        containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12).isActive = true
    }
}


class PlayerView: UIView {
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
}

class VideoCell: ExampleCell {
    
    public var playerView: PlayerView = {
        let v = PlayerView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        return v
    }()
    
    
    
    
    
    override func setupUIElements() {
        super.setupUIElements()
        
        containerView.addSubview(playerView)
        
        // Handle layout...
        playerView.leadingAnchor.constraint(equalTo: super.containerView.leadingAnchor, constant: 12).isActive = true
        playerView.topAnchor.constraint(equalTo: super.containerView.topAnchor, constant: 12).isActive = true
        playerView.trailingAnchor.constraint(equalTo: super.containerView.trailingAnchor, constant: -12).isActive = true
        playerView.bottomAnchor.constraint(equalTo: super.containerView.bottomAnchor, constant: -12).isActive = true
    }
    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        playerView.player?.pause()
////        player = nil
    
//    }
    
    private weak var playtimeObserver: NSObjectProtocol?

    // This function is called during the cell dequeue process and will load the image
    // using the `CellModel` struct. However, this would be replaced with your method.
    public override func configureCell(someCellModel: ExampleCellModel) {
        
        let urlString = someCellModel.urlString
        guard let url = URL(string: urlString) else {
            return
        }
        
        let playerItem = CachableAVPlayerItem(url: url, delegate: nil)
        let player = AVPlayer(playerItem: playerItem)
        
        if playtimeObserver != nil {
            NotificationCenter.default.removeObserver(playtimeObserver!)
            playtimeObserver = nil
        }
        playtimeObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main, using: { [weak self] (notification) in
            guard let strongSelf = self else { return }
            strongSelf.playerView.player?.seek(to: CMTime.zero)
            strongSelf.playerView.player?.play()
        })
        
        playerView.player = player
    }
    
}


























// MARK: - ImageCell

class ImageCell: ExampleCell {

    // Initialize the URLImageView within the cell as a variable.
    // NOTE: The second initializer is used which does NOT have the urlString argument.
    private lazy var imageView: URLImageView = {
        let img = URLImageView(delegate: nil, cachePolicy: .allow, defaultImage: nil)
        img.translatesAutoresizingMaskIntoConstraints = false
        img.backgroundColor = .gray
        return img
    }()
    
    
    
    override func setupUIElements() {
        super.setupUIElements()
        
        super.containerView.addSubview(imageView)
        
        // Handle layout...
        imageView.leadingAnchor.constraint(equalTo: super.containerView.leadingAnchor, constant: 12).isActive = true
        imageView.topAnchor.constraint(equalTo: super.containerView.topAnchor, constant: 12).isActive = true
        imageView.trailingAnchor.constraint(equalTo: super.containerView.trailingAnchor, constant: -12).isActive = true
        imageView.bottomAnchor.constraint(equalTo: super.containerView.bottomAnchor, constant: -12).isActive = true
    }
    
    // This function is called during the cell dequeue process and will load the image
    // using the `CellModel` struct. However, this would be replaced with your method.
    public override func configureCell(someCellModel: ExampleCellModel) {
        imageView.loadImageFrom(urlString: someCellModel.urlString)
        
//        imageView.loadImageFrom(urlString: someCellModel.urlString, progressHandler: { (progress) in
//            print("current downlod progress: \(progress)")
//        }, completion: {
//            print("Image has finished loading")
//        }) { (error) in
//            print("Error loading image")
//        }
    }

}
