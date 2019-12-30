//
//  ViewController.swift
//  Celestial
//
//  Created by ChrishonWyllie on 12/25/2019.
//  Copyright (c) 2019 ChrishonWyllie. All rights reserved.
//

import UIKit
import Celestial
import AVFoundation

class ViewController: UIViewController {
     
    // MARK: - Variables

    private var player: AVPlayer!





    // MARK: - UI Elements

    private lazy var imageView: URLImageView = {
        let urlString = "https://picsum.photos/400/800/?random"
        let img = URLImageView(urlString: urlString, delegate: self)
        img.translatesAutoresizingMaskIntoConstraints = false
        img.contentMode = .scaleAspectFill
        img.layer.cornerRadius = 10
        img.clipsToBounds = true
        img.backgroundColor = .darkGray
        return img
    }()









    // MARK: - View life cycle
 
     override func viewDidLoad() {
             super.viewDidLoad()
             // Do any additional setup after loading the view, typically from a nib.
     //        Celestial.shared.store(<#T##image: UIImage?##UIImage?#>, with: <#T##String#>)
         setupUI()
     }

     override func didReceiveMemoryWarning() {
         super.didReceiveMemoryWarning()
         // Dispose of any resources that can be recreated.
     }
}
 














// MARK: - Setup functions

extension ViewController {
     
     private func setupUI() {
        setupURLImageView()
//        setupImageCachingCollectionView()
//        setupCachableAVPlayerItem()
    }

    private func setupURLImageView() {
         view.addSubview(imageView)
         
         imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
         imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
         imageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
         imageView.widthAnchor.constraint(equalToConstant: 200).isActive = true
     }

    private func setupImageCachingCollectionView() {
        //        Celestial.shared.store(<#T##image: UIImage?##UIImage?#>, with: <#T##String#>)
    }

    private func setupCachableAVPlayerItem() {
        let urlString = "http://www.hochmuth.com/mp3/Tchaikovsky_Nocturne__orch.mp3"
        guard let url = URL(string: urlString) else {
            return
        }
        
        let playerItem = CachableAVPlayerItem(url: url, delegate: self)
        player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = false
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerLayer.frame = UIScreen.main.bounds
        self.view.layer.addSublayer(playerLayer)
        player.play()



        Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true) { (timer) in
            DispatchQueue.main.async {
                self.player.pause()
                playerLayer.removeFromSuperlayer()
                self.player = nil

                if let _ = Celestial.shared.video(for: urlString) {
                    
                    // At this point, the video will already be cached
                    let playerItem2 = CachableAVPlayerItem(url: url, delegate: self)
                    
                    self.player = AVPlayer(playerItem: playerItem2)
                    self.player.automaticallyWaitsToMinimizeStalling = false
                    let playerLayer = AVPlayerLayer(player: self.player)
                    playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    playerLayer.frame = UIScreen.main.bounds
                    self.view.layer.addSublayer(playerLayer)
                    self.player.play()
                }
            }
        }
    }

 }
 
 

// MARK: - URLImageView delegate

extension ViewController: URLImageViewDelegate {
    
    func urlImageView(_ view: URLImageView, downloadCompletedAt urlString: String) {
        print("download completed with url string: \(urlString)")
        print("image has been cached?: \(view.cachePolicy == .allow)")
    }
    
    func urlImageView(_ view: URLImageView, downloadFailedWith error: Error) {
        print("downlaod failed with error: \(error)")
    }
    
    func urlImageView(_ view: URLImageView, downloadProgress progress: CGFloat, humanReadableProgress: String) {
        print("download progress: \(progress)")
        print("human readable download progress: \(humanReadableProgress)")
    }
}










// MARK: - CachingPlayerItemDelegate

extension ViewController: CachableAVPlayerItemDelegate {

    func playerItem(_ playerItem: CachableAVPlayerItem, didFinishDownloadingData data: Data) {
        print("File is downloaded and ready for storing")
        print("asset duration after downloading: \(CMTimeGetSeconds(playerItem.asset.duration))")
    }

    func playerItem(_ playerItem: CachableAVPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int) {
//        print("\(bytesDownloaded)/\(bytesExpected)")
//        let downloadProgress = Float(bytesDownloaded) / Float(bytesExpected)
//        print("download progress: \(downloadProgress * 100)%")
    }

    func playerItemReadyToPlay(_ playerItem: CachableAVPlayerItem) {
        print("video is ready to play")
    }

    func playerItemPlaybackStalled(_ playerItem: CachableAVPlayerItem) {
        print("Not enough data for playback. Probably because of the poor network. Wait a bit and try to play later.")
    }

    func playerItem(_ playerItem: CachableAVPlayerItem, downloadingFailedWith error: Error) {
        print(error)
    }

}
