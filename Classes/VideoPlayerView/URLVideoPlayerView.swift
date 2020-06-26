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
    
    internal enum requiredAssetKeys: String, CaseIterable {
        case playable
        case duration
        case tracks
        case hasProtectedContent
        case exportable
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
                              progressHandler: DownloadTaskProgressHandler?,
                              completion: (() -> ())?,
                              errorHandler: DownloadTaskErrorHandler?) {
            
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
        
        if Celestial.shared.videoExists(for: url, cacheLocation: cacheLocation) {
            setupPlayerIfVideoHasBeenCached(from: url)
        } else {
            
            // Async load the video regardless of whether it has been cached,
            // due to UI blocking creation of an AVURLAsset
            
            asyncSetupPlayableAsset(from: url) { [weak self] (playableAsset, error) in
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
            
            
            
            downloadModel = GenericDownloadModel(sourceURL: url, delegate: self)
                
            if DownloadTaskManager.shared.downloadIsPaused(for: url) == true {
                DownloadTaskManager.shared.resumeDownload(model: downloadModel)
            } else if DownloadTaskManager.shared.downloadIsInProgress(for: url) {
                // Use thumbnail?
                
            } else {
                DebugLogger.shared.addDebugMessage("\(String(describing: type(of :self))) - starting new download to cache")
                DownloadTaskManager.shared.startDownload(model: downloadModel)
            }
        }
        
//        let videoResolution = playerItem.resolution!
//        let videoAspectRatio = playerItem.aspectRatio!
//        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - player item video resolution: \(videoResolution) and aspect ratio: \(videoAspectRatio)")
        
        
    }
    
    private func setupPlayerIfVideoHasBeenCached(from url: URL) {
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - getting video from cache")
        
        let resolution: CGSize = .zero
        
        switch cacheLocation {
        case .inMemory:
            
            DispatchQueue.global(qos: .default).async { [weak self] in
                guard let strongSelf = self else { return }
                guard let memoryCachedVideoData = Celestial.shared.videoData(for: url.absoluteString) else {
                    return
                }
                
                let playerItem = DataLoadablePlayerItem(data: memoryCachedVideoData.videoData,
                                                        mimeType: memoryCachedVideoData.originalURLMimeType,
                                                        fileExtension: memoryCachedVideoData.originalURLFileExtension)
                
                DispatchQueue.main.async {
                    let player = AVPlayer(playerItem: playerItem)
                    strongSelf.player = player
                    strongSelf.delegate?.urlVideoPlayerIsReadyToPlay?(strongSelf)
                }
            }
            
        case .fileSystem:
            
            guard let cachedVideoURL = Celestial.shared.videoURL(for: url, resolution: resolution) else {
                return
            }
            
            asyncSetupPlayableAsset(from: cachedVideoURL) { [weak self] (playableAsset, error) in
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
        }
    }
    
    private func asyncSetupPlayableAsset(from cachedVideoURL: URL, completion: @escaping (AVURLAsset, Error?) -> ()) {
        let asset = AVURLAsset(url: cachedVideoURL)
                    
        DispatchQueue.global(qos: .default).async {
            let assetKeys = URLVideoPlayerView.requiredAssetKeys.allCases
            let assetKeyValues = assetKeys.map { $0.rawValue }
            asset.loadValuesAsynchronously(forKeys: assetKeyValues) {
                for key in assetKeys {
                    var error: NSError? = nil
                    let status = asset.statusOfValue(forKey: key.rawValue, error: &error)
                    switch status {
                    case .failed:
                        completion(asset, error)
                    case .loaded:
                        if key == .playable && asset.isPlayable {
                            completion(asset, error)
                        }
                    default:
                        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - asset status: \(status)")
                    }
                }
            }
        }
    }
}































// MARK: - CachableDownloadModelDelegate

extension URLVideoPlayerView: CachableDownloadModelDelegate {
    
    func cachable(_ downloadTaskRequest: DownloadTaskRequestProtocol, didFinishDownloadingTo localTemporaryFileURL: URL) {
        
        let desiredResolution: CGSize = .zero
        
        let uncompressedDownloadedMediaData = try! Data(contentsOf: localTemporaryFileURL)
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - uncompressed video size: \(uncompressedDownloadedMediaData.sizeInMB) MB")
        
        switch cachePolicy {
        case .allow:
            
            getCachedAndResizedVideo(localTemporaryFileURL: localTemporaryFileURL, desiredResolution: desiredResolution) { (compressedVideoURL) in
                
                guard let compressedVideoURL = compressedVideoURL else {
                    return
                }
                
                if self.downloadTaskHandler != nil {
                    // This is only called if `loadImageFrom(urlString:, progressHandler:, completion:, errorHandler:)` was called.
                    // In which case, this property will be non-nil
                    self.downloadTaskHandler?.completionHandler?(compressedVideoURL)
                } else {
                    
                    self.delegate?.urlCachableView?(self, didFinishDownloading: compressedVideoURL)
                }
            }
            
        default:
            if downloadTaskHandler != nil {
                // This is only called if `loadImageFrom(urlString:, progressHandler:, completion:, errorHandler:)` was called.
                // In which case, this property will be non-nil
                downloadTaskHandler?.completionHandler?(localTemporaryFileURL)
            } else {
                
                delegate?.urlCachableView?(self, didFinishDownloading: localTemporaryFileURL)
            }
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

    
    
    
    
    
    
    private func getCachedAndResizedVideo(localTemporaryFileURL: URL, desiredResolution: CGSize, completion: @escaping (_ compressedCachedURL: URL?) -> ()) {
        
        guard let originalSourceURL = sourceURL else {
            completion(nil)
            return
        }
        
        switch cacheLocation {
        case .inMemory:
           
            let temporaryFileURL = FileStorageManager.shared.createTemporaryFileURL()
            FileStorageManager.shared.compressVideo(inputURL: localTemporaryFileURL, outputURL: temporaryFileURL) { (compressedVideoURL) in
                
                guard let compressedVideoURL = compressedVideoURL else {
                    completion(nil)
                    return
                }
                
                do {
                    let compressedDownloadedMediaData = try Data(contentsOf: compressedVideoURL)
                    
                    DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Compressed video to \(compressedDownloadedMediaData.sizeInMB) MB")
                    
                    let videoData = MemoryCachedVideoData(videoData: compressedDownloadedMediaData,
                                                          originalURLMimeType: originalSourceURL.mimeType(),
                                                          originalURLFileExtension: originalSourceURL.pathExtension)
                    
                    Celestial.shared.store(videoData: videoData, with: originalSourceURL.absoluteString)
                    
                    completion(compressedVideoURL)
                    
                } catch let error {
                    DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error getting data from contents of url: \(compressedVideoURL). Error: \(error)")
                    completion(nil)
                }
            }
            
        case .fileSystem:
           
            Celestial.shared.storeVideoURL(localTemporaryFileURL, withSourceURL: originalSourceURL, resolution: desiredResolution, completion: completion)
        }
    }
    
}
