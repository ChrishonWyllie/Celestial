//
//  URLVideoPlayerView.swift
//  Pods
//
//  Created by Chrishon Wyllie on 6/24/20.
//

import AVFoundation

@objc public protocol URLVideoPlayerViewDelegate: URLCachableViewDelegate {
    @objc optional func urlVideoPlayerIsReadyToPlay(_ view: URLVideoPlayerView)
}

/// Subclass of UIImageView which can download and display an image from an external URL,
/// then cache it for future use if desired.
/// This is used together with the Celestial cache to prevent needless downloading of the same images.
open class URLVideoPlayerView: VideoPlayerView, URLCachableView {
    
    // MARK: - Variables
       
    private weak var delegate: URLVideoPlayerViewDelegate?
    
    public private(set) var cachePolicy: MultimediaCachePolicy = .allow
    
    public private(set) var sourceURL: URL?
    
    public private(set) var cacheLocation: DownloadCompletionCacheLocation = .fileSystem
   
    private var downloadModel: GenericDownloadModel!
    
    private var downloadTaskHandler: DownloadTaskHandler<URL>?
    
    private static var requiredAssetKeys: [String] {
        return [
            "playable",
            "duration",
            "tracks",
            "hasProtectedContent"
        ]
    }
    
    
    
    
    
    
    
    
    
    // MARK: - Initializers
    
    public convenience init(delegate: URLVideoPlayerViewDelegate?,
                            sourceURLString: String,
                            cachePolicy: MultimediaCachePolicy = .allow,
                            cacheLocation: DownloadCompletionCacheLocation = .fileSystem) {
        self.init(delegate: delegate, cachePolicy: cachePolicy, cacheLocation: cacheLocation)
        loadVideoFrom(urlString: sourceURLString)
    }
    
    public convenience init(delegate: URLVideoPlayerViewDelegate?,
                            cachePolicy: MultimediaCachePolicy = .allow,
                            cacheLocation: DownloadCompletionCacheLocation = .fileSystem) {
        self.init(frame: .zero, delegate: delegate, cachePolicy: cachePolicy, cacheLocation: cacheLocation)
    }
    
    public convenience init(frame: CGRect,
                            delegate: URLVideoPlayerViewDelegate?,
                            cachePolicy: MultimediaCachePolicy,
                            cacheLocation: DownloadCompletionCacheLocation) {
        self.init(frame: frame, cachePolicy: cachePolicy, cacheLocation: cacheLocation)
        self.delegate = delegate
    }
    
    public required init(frame: CGRect,
                         cachePolicy: MultimediaCachePolicy,
                         cacheLocation: DownloadCompletionCacheLocation) {
        super.init(frame: frame)
        self.cachePolicy = cachePolicy
        self.cacheLocation = cacheLocation
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - has been deinitialized")
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // MARK: - Functions
    
    public func loadVideoFrom(urlString: String) {
        acquireVideo(from: urlString)
    }
    
    public func loadVideoFrom(urlString: String,
                              progressHandler: (DownloadTaskProgressHandler?),
                              completion: (() -> ())?,
                              errorHandler: (DownloadTaskErrorHandler?)) {
            
        acquireVideo(from: urlString)
        
        // First, set up the download task handler
        
        downloadTaskHandler = DownloadTaskHandler<URL>()
        downloadTaskHandler?.completionHandler = { (_) in
            DispatchQueue.main.async {
                completion?()
            }
        }
        downloadTaskHandler?.progressHandler = { (downloadProgress) in
            progressHandler?(downloadProgress)
        }
        downloadTaskHandler?.errorHandler = { (error) in
            errorHandler?(error)
        }
    }
    
    private func acquireVideo(from urlString: String) {
        
        guard let url = URL(string: urlString) else {
            return
        }
        self.sourceURL = url
        
        let resolution: CGSize = .zero
        
        // Async load the video regardless of whether it has been cached, due to UI blocking creation of an AVURLAsset
        
        let urlOfVideoToPlay: URL = Celestial.shared.videoURL(for: url, resolution: resolution) ?? url
        
        asyncSetupPlayableAsset(with: urlOfVideoToPlay) { [weak self] (playableAsset, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                fatalError("Error loading video asset: \(String(describing: error))")
            }
            let playerItem = AVPlayerItem(asset: playableAsset)
            DispatchQueue.main.async {
                let player = AVPlayer(playerItem: playerItem)
                strongSelf.player = player
                strongSelf.delegate?.urlVideoPlayerIsReadyToPlay?(strongSelf)
            }
        }
        
        if Celestial.shared.videoExists(for: url, cacheLocation: cacheLocation) {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - playing from cache")
        } else {
            
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async { [weak self] in
                guard let strongSelf = self else { return }
                            
                strongSelf.downloadModel = GenericDownloadModel(sourceURL: url, delegate: strongSelf)
                
                if DownloadTaskManager.shared.downloadIsPaused(for: url) == true {
                    DownloadTaskManager.shared.resumeDownload(model: strongSelf.downloadModel)
                } else if DownloadTaskManager.shared.downloadIsInProgress(for: url) {
                    // Use thumbnail?
                    
                } else {
                    DebugLogger.shared.addDebugMessage("\(String(describing: type(of :self))) - starting new download to cache")
                    DownloadTaskManager.shared.startDownload(model: strongSelf.downloadModel)
                }
            }
        }
        
//        let videoResolution = playerItem.resolution!
//        let videoAspectRatio = playerItem.aspectRatio!
//        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - player item video resolution: \(videoResolution) and aspect ratio: \(videoAspectRatio)")
        
        
    }
    
    private func asyncSetupPlayableAsset(with url: URL, completion: @escaping (AVURLAsset, Error?) -> ()) {
        let asset = AVURLAsset(url: url)
                    
        DispatchQueue.global(qos: .default).async {
            asset.loadValuesAsynchronously(forKeys: URLVideoPlayerView.requiredAssetKeys) {
                for key in URLVideoPlayerView.requiredAssetKeys {
                    var error: NSError? = nil
                    let status = asset.statusOfValue(forKey: key, error: &error)
                    switch status {
                    case .failed:
                        completion(asset, error)
                    case .loading:
                        print("Still loading")
                    case .loaded:
                        if asset.isPlayable {
                            completion(asset, error)
                        }
                    default:
                        print("asset status: \(status)")
                    }
                }
            }
        }
    }
}































// MARK: - CachableDownloadModelDelegate

extension URLVideoPlayerView: CachableDownloadModelDelegate {
    
    func cachable(_ downloadTaskRequest: DownloadTaskRequestProtocol, didFinishDownloadingTo localTemporaryFileURL: URL) {
        
        
        var videoURLToDisplay: URL?
        let desiredResolution: CGSize = .zero
        
        switch cachePolicy {
        case .allow:
            
            videoURLToDisplay = getCachedAndResizedVideo(localTemporaryFileURL: localTemporaryFileURL, desiredResolution: desiredResolution)
        default:
            videoURLToDisplay = getResizedVideoURL(from: localTemporaryFileURL, desiredResolution: desiredResolution)
            FileStorageManager.shared.deleteFileAt(intermediateTemporaryFileLocation: localTemporaryFileURL)
        }
        
        guard let resizedAndPossiblyCachedVideoURL = videoURLToDisplay else {
            return
        }
        
        
        if downloadTaskHandler != nil {
            // This is only called if `loadImageFrom(urlString:, progressHandler:, completion:, errorHandler:)` was called.
            // In which case, this property will be non-nil
            downloadTaskHandler?.completionHandler?(resizedAndPossiblyCachedVideoURL)
        } else {
            
            delegate?.urlCachableView?(self, didFinishDownloading: resizedAndPossiblyCachedVideoURL)
        }
    }
    
    func cachable(_ downloadTaskRequest: DownloadTaskRequestProtocol, downloadFailedWith error: Error) {
        // TODO
        // MUST IMPLEMENT
    }
    
    func cachable(_ downloadTaskRequest: DownloadTaskRequestProtocol, downloadProgress progress: Float, humanReadableProgress: String) {
        if downloadTaskHandler != nil {
            // This is only called if `loadImageFrom(urlString:, progressHandler:, completion:, errorHandler:)` was called.
            // In which case, this property will be non-nil
            downloadTaskHandler?.progressHandler?(progress)
        } else {
            
            delegate?.urlCachableView?(self, downloadProgress: progress, humanReadableProgress: humanReadableProgress)
        }
    }

    
    
    
    
    
    
    private func getCachedAndResizedVideo(localTemporaryFileURL: URL, desiredResolution: CGSize) -> URL? {
        
        var resizedCachedVideoURL: URL?
        
        guard let originalSourceURL = sourceURL else {
            return nil
        }
        
        switch cacheLocation {
            case .inMemory:
               
                if let resizedVideoURL = getResizedVideoURL(from: localTemporaryFileURL, desiredResolution: desiredResolution) {
                    
                    let downloadedMediaData = try! Data(contentsOf: resizedVideoURL)
                    
                    let videoData = MemoryCachedVideoData(videoData: downloadedMediaData,
                                                              originalURLMimeType: originalSourceURL.mimeType(),
                                                              originalURLFileExtension: originalSourceURL.pathExtension)
                    
                    Celestial.shared.store(videoData: videoData, with: originalSourceURL.absoluteString)
                    
                    resizedCachedVideoURL = resizedVideoURL
                }
                
            case .fileSystem:
               
                resizedCachedVideoURL = Celestial.shared.storeVideoURL(localTemporaryFileURL, withSourceURL: originalSourceURL, resolution: desiredResolution)
               
               
        }
        
        return resizedCachedVideoURL
    }
    
    private func getResizedVideoURL(from localTemporaryFileURL: URL, desiredResolution: CGSize) -> URL? {
        
        // TODO
//        var resizedVideoURL: URL?
        
        // Some how resize Video
        
        fatalError("Not implemented")
    }
}
