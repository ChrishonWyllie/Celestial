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

fileprivate enum ExpectedMediaType {
    case image, video
}

class ViewController: UIViewController {
     
    // MARK: - Variables

    private var player: AVPlayer!

    private var expectedMediaType: ExpectedMediaType = .video
//    private var expectedMediaType: ExpectedMediaType = .image

    private let cellReuseIdentifier = "cell reuse identifier"
    private var cellModels: [ExampleCellModel] = []
    private var downloadedImageCellModels: [ImageCellModel] = []
    private var downloadedVideoCellModels: [VideoCellModel] = []
    
    
    
    


    // MARK: - UI Elements
    
    private lazy var toggleDataSourceButton: UIBarButtonItem = {
        let btn = UIBarButtonItem(title: "Toggle", style: .plain, target: self, action: #selector(toggleDataSource))
        return btn
    }()
    
    private lazy var clearCacheButton: UIBarButtonItem = {
        let btn = UIBarButtonItem(title: "Clear Cache", style: .plain, target: self, action: #selector(clearDataSourceCache))
        return btn
    }()
    
    private lazy var cacheInfoButton: UIBarButtonItem = {
        let btn = UIBarButtonItem(title: "Cache Info", style: .plain, target: self, action: #selector(getCachedInfo))
        return btn
    }()

    private lazy var imageView: URLImageView = {
        let urlString = "https://picsum.photos/400/800/?random"
        let img = URLImageView(delegate: self, sourceURLString: urlString)
        img.translatesAutoresizingMaskIntoConstraints = false
        img.contentMode = .scaleAspectFill
        img.layer.cornerRadius = 10
        img.clipsToBounds = true
        img.backgroundColor = .darkGray
        return img
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.scrollDirection = .vertical
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = UIColor.systemGray3
        cv.allowsMultipleSelection = true
        cv.prefetchDataSource = self
        cv.isPrefetchingEnabled = true
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
        
        Celestial.shared.setDebugMode(on: true)
        
        navigationItem.rightBarButtonItems = [toggleDataSourceButton, clearCacheButton, cacheInfoButton]
        
//        setupURLImageView()
//        setupCachableAVPlayerItem()
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        view.addSubview(collectionView)
        
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: String(describing: ImageCell.self))
        collectionView.register(VideoCell.self, forCellWithReuseIdentifier: String(describing: VideoCell.self))
        
        switch expectedMediaType {
        case .image: getRandomImages()
        case .video: getRandomVideos()
        }
    }
    
    @objc private func toggleDataSource() {
        
        if expectedMediaType == .video {
            if let visibleCells = collectionView.visibleCells as? [VideoCell] {
                visibleCells.forEach { (cell) in
                    cell.playerView.player?.pause()
                }
            }
        }
        
        cellModels.removeAll()
        collectionView.reloadData()
        
        let newDataSourceType: ExpectedMediaType = expectedMediaType == .image ? .video : .image
        self.expectedMediaType = newDataSourceType
        
        switch expectedMediaType {
        case .image: getRandomImages()
        case .video: getRandomVideos()
        }
    }

    @objc private func clearDataSourceCache() {
        switch expectedMediaType {
        case .image: Celestial.shared.clearAllImages()
        case .video: Celestial.shared.clearAllVideos()
        }
    }
    
    @objc private func getCachedInfo() {
        let cacheInfo = Celestial.shared.getCacheInfo()
        for info in cacheInfo {
            print(info)
        }
    }
}









// MARK: - Set up Image caching

extension ViewController {
    
    private func setupURLImageView() {
        
        view.addSubview(imageView)
         
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        
    }
    
    private func getRandomImages() {
            
        guard let url = URL(string: "https://picsum.photos/v2/list?limit=25") else {
            return
        }
        
        if self.downloadedImageCellModels.count == 0 {
            let group = DispatchGroup()
            
            group.enter()
            
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data else { return }
                do {
                    guard let jsonDataArray = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [[String: AnyObject]] else {
                        return
                    }
                    
                    jsonDataArray.forEach { (jsonObject) in
                        let urlSessionObject = URLSessionObject(object: jsonObject)
                        self.downloadedImageCellModels.append(ImageCellModel(urlString: urlSessionObject.downloadURL))
                    }
                    
                    group.leave()
                    
                } catch let error {
                    print("error converting data to json: \(error)")
                }
                
            }.resume()
            
            group.notify(queue: DispatchQueue.main) {
                self.cellModels = self.downloadedImageCellModels
                self.collectionView.reloadData()
            }
            
        } else {
            self.cellModels = downloadedImageCellModels
            self.collectionView.reloadData()
        }
    }
}













// MARK: - Set up Video caching

extension ViewController {
    
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

                if let _ = Celestial.shared.videoData(for: urlString) {
                    
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

    private func getRandomVideos() {
        if downloadedVideoCellModels.count == 0 {
            downloadedVideoCellModels = TestURLs.Videos.urlStrings.map { VideoCellModel(urlString: $0) }
            cellModels = downloadedVideoCellModels
            collectionView.reloadData()
        } else {
            cellModels = downloadedVideoCellModels
            collectionView.reloadData()
        }
    }
}














// MARK: - UICollectionView delegate and datasource

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ExampleCell?
        
        switch expectedMediaType {
        case .image:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ImageCell.self), for: indexPath) as? ImageCell
        case .video:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: VideoCell.self), for: indexPath) as? VideoCell
        }
        
        let cellModel = cellModels[indexPath.item]
        
        cell?.configureCell(someCellModel: cellModel)
        
        return cell!
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width, height: 400.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let videoCell = (cell as? VideoCell) else { return }
        videoCell.playerView.player?.play()
        
        
//        let visibleCells = collectionView.visibleCells
//        let minIndex = visibleCells.startIndex
//        let currentIndex = collectionView.visibleCells.firstIndex(of: cell)
        
//        if currentIndex == minIndex {
//            videoCell.playerView.player?.play()
//        } else {
//            return
//        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let videoCell = cell as? VideoCell else { return }
        videoCell.playerView.player?.pause()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let videoCell = (collectionView.cellForItem(at: indexPath) as? VideoCell) else { return }
        videoCell.playerView.player!.play()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let videoCell = (collectionView.cellForItem(at: indexPath) as? VideoCell) else { return }
        videoCell.playerView.player?.pause()
    }
    
}

extension ViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        print("prefetching items at indexPaths: \(indexPaths)")
        
        for indexPath in indexPaths {
            
            let cellModel = cellModels[indexPath.item]
            
            guard let url = URL(string: cellModel.urlString) else {
                fatalError()
            }
            
            switch Celestial.shared.downloadState(for: url) {
            case .none:
                Celestial.shared.startDownload(for: url)
            case .paused:
                Celestial.shared.resumeDownload(for: url)
            case .downloading, .finished:
                // Nothing more to do
                continue
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        print("canceling prefetching items at indexPaths: \(indexPaths)")
        
        for indexPath in indexPaths {
            
            let cellModel = cellModels[indexPath.item]
            
            guard let url = URL(string: cellModel.urlString) else {
                fatalError()
            }
            
            switch Celestial.shared.downloadState(for: url) {
            case .none, .finished, .paused:
                // Nothing more to do
                continue
            case .downloading:
                Celestial.shared.pauseDownload(for: url)
            }
        }
    }
}













 
 

// MARK: - URLCachableViewDelegate

extension ViewController: URLCachableViewDelegate {
    
    func urlCachableView(_ view: URLCachableView, didFinishDownloading media: Any) {
        print("download completed with url string: \(String(describing: view.sourceURL?.absoluteString))")
        print("image has been cached?: \(view.cachePolicy == .allow)")
    }
    
    func urlCachableView(_ view: URLCachableView, downloadFailedWith error: Error) {
        print("downlaod failed with error: \(error)")
    }
    
    func urlCachableView(_ view: URLCachableView, downloadProgress progress: Float, humanReadableProgress: String) {
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
