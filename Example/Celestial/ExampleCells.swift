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

class VideoCell: UICollectionViewCell {
    
    private var player: AVPlayer!
    
    
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // This function is called during the cell dequeue process and will load the image
    // using the `CellModel` struct. However, this would be replaced with your method.
    public func configureCell(someCellModel: VideoCellModel) {
        let urlString = someCellModel.urlString
        guard let url = URL(string: urlString) else {
            return
        }
        
        let playerItem = CachableAVPlayerItem(url: url, delegate: nil)
        player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = false
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerLayer.frame = UIScreen.main.bounds
        self.layer.addSublayer(playerLayer)
        player.play()
    }
}

class ImageCell: UICollectionViewCell {

    // Initialize the URLImageView within the cell as a variable.
    // NOTE: The second initializer is used which does NOT have the urlString argument.
    private lazy var imageView: URLImageView = {
        let img = URLImageView(delegate: nil, cachePolicy: .allow, defaultImage: nil)
        img.translatesAutoresizingMaskIntoConstraints = false
        img.backgroundColor = .gray
        return img
    }()
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(imageView)
        
        // Handle layout...
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        imageView.topAnchor.constraint(equalTo: topAnchor, constant: 12).isActive = true
        imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12).isActive = true
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // This function is called during the cell dequeue process and will load the image
    // using the `CellModel` struct. However, this would be replaced with your method.
    public func configureCell(someCellModel: ImageCellModel) {
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
