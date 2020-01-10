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

fileprivate struct URLSessionObject {
    let author: String
    let downloadURL: String
    let height: NSNumber
    let id: NSNumber
    let url: String
    let width: NSNumber
    
    init(object: [String: AnyObject]) {
        author = object["author"] as? String ?? ""
        downloadURL = object["download_url"] as? String ?? ""
        height = object["height"] as? NSNumber ?? 0
        id = object["id"] as? NSNumber ?? 0
        url = object["url"] as? String ?? ""
        width = object["width"] as? NSNumber ?? 0
    }
}

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

    private let cellReuseIdentifier = "cell reuse identifier"
    private var imageCellModels: [ImageCellModel] = []
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.scrollDirection = .vertical
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .white
        cv.delegate = self
        cv.dataSource = self
        return cv
    }()
    







    // MARK: - View life cycle
 
     override func viewDidLoad() {
         super.viewDidLoad()
         // Do any additional setup after loading the view, typically from a nib.
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
//        setupURLImageView()
        setupImageCachingCollectionView()
//        setupCachableAVPlayerItem()
        setupVideoCachingCollectionView()
    }

    private func setupURLImageView() {
        
        view.addSubview(imageView)
         
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        
    }
    
    

    private func setupImageCachingCollectionView() {
        view.addSubview(collectionView)
        
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        
        getRandomImages()
        
    }
    
    private func getRandomImages() {
        
//        TestURLs.urlStrings.forEach { (urlString) in imageCellModels.append(ImageCellModel(urlString: urlString)) }
//        collectionView.reloadData()
//        return
        
        guard let url = URL(string: "https://picsum.photos/v2/list?limit=25") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else { return }
            do {
                guard let jsonDataArray = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [[String: AnyObject]] else {
                    return
                }
                jsonDataArray.forEach { (jsonObject) in
                    let urlSessionObject = URLSessionObject(object: jsonObject)
                    
                    DispatchQueue.main.async {
                        self.collectionView.performBatchUpdates({
                            self.imageCellModels.append(ImageCellModel(urlString: urlSessionObject.downloadURL))
                            let lastIndexPath = IndexPath(item: self.imageCellModels.count - 1, section: 0)
                            self.collectionView.insertItems(at: [lastIndexPath])
                        }, completion: nil)
                    }
                }
                
            } catch let error {
                print("error converting data to json: \(error)")
            }
            
        }.resume()
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


        // Recreate the video after a determined amount of time
        // NOTE: this time interval may be too short or too long depending on the video at the urlString
        // Expected behavior:
        // The video will have been cached already, thus causing the recreated video
        // to begin immediately using the cached Data, instead of making another URL request to the server.
        // The `playerItem(_ playerItem: CachableAVPlayerItem, didFinishDownloadingData data: Data)` delegate
        // function below should only be called ONCE (due to being already cached)
        
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

    private func setupVideoCachingCollectionView() {
        // TBD
    }
}











// MARK: - UICollectionView delegate and datasource

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageCellModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ImageCell?
        
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as? ImageCell
        let cellModel = imageCellModels[indexPath.item]
        
        cell?.configureCell(someCellModel: cellModel)
        
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width, height: 200.0)
    }
}














 
 

// MARK: - URLImageView delegate

extension ViewController: URLImageViewDelegate {
    
    func urlImageView(_ view: URLImageView, didFinishDownloading image: UIImage) {
        print("download completed with url string: \(String(describing: view.urlString))")
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

    func playerItem(_ playerItem: CachableAVPlayerItem, didFinishDownloading data: Data) {
        print("File is downloaded and ready for storing")
        print("asset duration after downloading: \(CMTimeGetSeconds(playerItem.asset.duration))")
        print("video has been cached?: \(playerItem.cachePolicy == .allow)")
    }
    
    func playerItem(_ playerItem: CachableAVPlayerItem, downloadFailedWith error: Error) {
        print("Error downloading video: \(error.localizedDescription)")
    }
    
    
    func playerItem(_ playerItem: CachableAVPlayerItem, downloadProgress progress: CGFloat, humanReadableProgress: String) {
        print("download progress: \(progress)")
        print("human readable download progress: \(humanReadableProgress)")
    }

    func playerItemReadyToPlay(_ playerItem: CachableAVPlayerItem) {
        print("video is ready to play")
    }

    func playerItemPlaybackStalled(_ playerItem: CachableAVPlayerItem) {
        print("Not enough data for playback. Probably because of the poor network. Wait a bit and try to play later.")
    }

}
