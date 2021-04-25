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

extension String {
    func estimateFrameForText(with font: UIFont, textContainerWidth: CGFloat? = nil) -> CGRect {
        let someArbitraryWidthValue: CGFloat = 200
        let size = CGSize(width: textContainerWidth ?? someArbitraryWidthValue, height: 1000)
        let options = NSStringDrawingOptions
            .usesFontLeading
            .union(.usesLineFragmentOrigin)
        return NSString(string: self)
            .boundingRect(with: size,
                          options: options,
                          attributes: [NSAttributedString.Key.font: font],
                          context: nil)
    }
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
    
    private lazy var playerView: URLVideoPlayerView = {
        let urlString = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
        let v = URLVideoPlayerView(delegate: nil, sourceURLString: urlString)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
//        v.isMuted = true
        v.play()
        return v
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .vertical
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            cv.backgroundColor = UIColor.systemGray3
        } else {
            // Fallback on earlier versions
            cv.backgroundColor = .gray
        }
        cv.allowsMultipleSelection = true
        cv.prefetchDataSource = self
        cv.isPrefetchingEnabled = true
        cv.delegate = self
        cv.dataSource = self
        return cv
    }()
    
    // For the purpose of creating dynamic cell heights
    private var cellSizes: [IndexPath: CGSize] = [:]







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
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemGroupedBackground
        } else {
            // Fallback on earlier versions
        }
        navigationItem.rightBarButtonItems = [toggleDataSourceButton, clearCacheButton, cacheInfoButton]
        
//        setupURLImageView()
//        setupURLVideoPlayerView()
//        setupCachableAVPlayerItem()
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        view.addSubview(collectionView)
        
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        if #available(iOS 11.0, *) {
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            // Fallback on earlier versions
            collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        
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
                    cell.playerView.pause()
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
        Celestial.shared.reset()
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
         
        let imageDimension: CGFloat = 300.0
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: imageDimension).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: imageDimension).isActive = true
        
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
    
    private func setupURLVideoPlayerView() {
        view.addSubview(playerView)
         
//        let playerDimension: CGFloat = 300.0
        playerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        playerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
//        playerView.heightAnchor.constraint(equalToConstant: playerDimension).isActive = true
//        playerView.widthAnchor.constraint(equalToConstant: playerDimension).isActive = true
        
//        let constant: CGFloat = 8
//        playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: constant).isActive = true
//        if #available(iOS 11.0, *) {
//            playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: constant).isActive = true
//        } else {
//            // Fallback on earlier versions
//            playerView.topAnchor.constraint(equalTo: view.topAnchor, constant: constant).isActive = true
//        }
//        playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -constant).isActive = true
//        playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -constant).isActive = true
    }
    
    private func setupCachableAVPlayerItem() {
        let urlString = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
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

                if let _ = Celestial.shared.videoFromMemoryCache(sourceURLString: urlString) {
                    
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

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, VideoCellDelegate {
    
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
            (cell as? VideoCell)?.delegate = self
        }
        
        let cellModel = cellModels[indexPath.item]
        
        cell?.configureCell(someCellModel: cellModel)
        
        return cell!
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // If there exists a calculated size for this indexPath
        // i.e., if the video's resolution has been calculated and can return a proper size for the cell
        // while keeping the aspect ratio of the video
        if let calculatedSize = cellSizes[indexPath] {
            return calculatedSize
        }
        // Otherwise, use a default size
        return CGSize(width: collectionView.frame.size.width, height: 400.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        guard let videoCell = (cell as? VideoCell) else { return }
//        videoCell.playerView.play()
        
        
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
//        guard let videoCell = cell as? VideoCell else { return }
//        videoCell.playerView.pause()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        guard let videoCell = (collectionView.cellForItem(at: indexPath) as? VideoCell) else { return }
//        videoCell.playerView.play()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//        guard let videoCell = (collectionView.cellForItem(at: indexPath) as? VideoCell) else { return }
//        videoCell.playerView.pause()
    }
    
    func videoCell(_ cell: VideoCell, requestsContainerSizeChanges requiredSize: CGSize) {
        let indexPath: IndexPath
        
        if let indexPathForCell = collectionView.indexPath(for: cell) {
            indexPath = indexPathForCell
        } else {
            // The UICollectionView cannot reach this cell, as it may not have been dequeued yet (or it has been recycled)
            let urlString = cell.playerView.sourceURL?.absoluteString
            guard let arrayElementIndex = cellModels.firstIndex(where: { $0.urlString == urlString }) else {
                // This is virtually guaranteed since there must exist a cellModel where its urlString
                // is the same as the one that this VideoCell's playerView is using.
                return
            }
            let index = Int(arrayElementIndex)
            indexPath = IndexPath(item: index, section: 0)
        }
        
        let cellModel = cellModels[indexPath.item]
        
        // NOTE
        // Without this seeminglyArbitraryValueToFillGap, the estimated text frame has some extra padding
        // This is NOT a proper solution for dynamic height cells
        let seeminglyArbitraryValueToFillGap: CGFloat = 40
        let titleLabelHeight: CGFloat = cellModel.urlString.estimateFrameForText(with: UIFont.systemFont(ofSize: 17)).height - seeminglyArbitraryValueToFillGap
        let progressLabelHeight: CGFloat = Constants.progressLabelHeight
        let progressBarHeight: CGFloat = 4
        let totalVerticalPadding: CGFloat = cell.getTotalVerticalPadding()
        let calculatedHeight = requiredSize.height + titleLabelHeight + progressLabelHeight + progressBarHeight + totalVerticalPadding
        let calculatedSize = CGSize(width: collectionView.frame.size.width, height: calculatedHeight)
        
        if cellSizes[indexPath] != nil {
            return
        }
        
        cellSizes[indexPath] = calculatedSize
        
        // Animate the cell size change
        collectionView.performBatchUpdates({
            collectionView.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }
}

extension ViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        print("prefetching items at indexPaths: \(indexPaths)")
        
        let min = indexPaths.min()!
        let max = indexPaths.max()!
        let prefetchedModels = Array(cellModels[min.item...max.item])
        let urlStrings = prefetchedModels.map { $0.urlString }
        print("Prefetching for indexPath items: \(Array(min.item...max.item))")
        Celestial.shared.prefetchResources(at: urlStrings)
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        print("canceling prefetching items at indexPaths: \(indexPaths)")
        
        let min = indexPaths.min()!
        let max = indexPaths.max()!
        let cancelledPrefetchedModels = Array(cellModels[min.item...max.item])
        let urlStrings = cancelledPrefetchedModels.map { $0.urlString }
        print("Cancelling prefetching for indexPath items: \(Array(min.item...max.item))")
        Celestial.shared.pausePrefetchingForResources(at: urlStrings, cancelCompletely: false)
    }
}













 
 

// MARK: - URLCachableViewDelegate

extension ViewController: URLCachableViewDelegate {
    
    func urlCachableView(_ view: URLCachableView, didFinishDownloading media: Any) {
        print("download completed with url string: \(String(describing: view.sourceURL?.absoluteString))")
        print("image has been cached?: \(view.cacheLocation != .none)")
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
        print("video has been cached?: \(playerItem.cacheLocation != .none)")
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
