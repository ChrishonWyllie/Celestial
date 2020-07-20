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
@IBDesignable open class URLVideoPlayerView: VideoPlayerView, URLCachableView {
    
    // MARK: - Variables
       
    private weak var delegate: URLVideoPlayerViewDelegate?
    
    public private(set) var sourceURL: URL?
    
    public private(set) var cacheLocation: ResourceCacheLocation = .fileSystem
   
    private var downloadTaskRequest: DownloadTaskRequest!
    
    private var downloadTaskHandler: DownloadTaskHandler<URL>?
    
    internal enum LoadableAssetKeys: String, CaseIterable {
        case playable
        case duration
        case tracks
        case hasProtectedContent
        case exportable
    }
    
    fileprivate var playImmediatelyWhenReady: Bool = false
    
    public var isMuted: Bool {
        set {
            // Set local variable.
            // Wait for player to be initialized if not already
            _isMuted = newValue
            if super.player != nil {
                super.player?.isMuted = newValue
            }
        }
        get {
            // If the player doesn't exist yet, return local variable
            return super.player?.isMuted ?? _isMuted
        }
    }
    private var _isMuted: Bool = false
    
    
    
    
    
    
    // MARK: - Initializers
    
    public convenience init(delegate: URLVideoPlayerViewDelegate?,
                            sourceURLString: String,
                            cacheLocation: ResourceCacheLocation = .fileSystem) {
        self.init(delegate: delegate, cacheLocation: cacheLocation)
        loadVideoFrom(urlString: sourceURLString)
    }
    
    public convenience init(delegate: URLVideoPlayerViewDelegate?,
                            cacheLocation: ResourceCacheLocation = .fileSystem) {
        self.init(frame: .zero, delegate: delegate, cacheLocation: cacheLocation)
    }
    
    public convenience init(frame: CGRect,
                            delegate: URLVideoPlayerViewDelegate?,
                            cacheLocation: ResourceCacheLocation) {
        self.init(frame: frame, cacheLocation: cacheLocation)
        self.delegate = delegate
    }
    
    public required init(frame: CGRect,
                         cacheLocation: ResourceCacheLocation) {
        super.init(frame: frame)
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
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.acquireVideo(from: urlString, progressHandler: nil, completion: nil, errorHandler: nil)
        }
    }
    
    public func loadVideoFrom(urlString: String,
                              progressHandler: DownloadTaskProgressHandler?,
                              completion: OptionalCompletionHandler,
                              errorHandler: DownloadTaskErrorHandler?) {
            
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.acquireVideo(from: urlString,
                               progressHandler: progressHandler,
                               completion: completion,
                               errorHandler: errorHandler)
        }
    }
    
    private func acquireVideo(from urlString: String,
                              progressHandler: DownloadTaskProgressHandler?,
                              completion: OptionalCompletionHandler,
                              errorHandler: DownloadTaskErrorHandler?) {
        
        guard let sourceURL = URL(string: urlString) else {
            return
        }
        self.sourceURL = sourceURL
        
        reset()
        
        downloadTaskRequest = DownloadTaskRequest(sourceURL: sourceURL, delegate: self)
        
        let resourceExistenceState = Celestial.shared.determineResourceExistenceState(forSourceURL: sourceURL,
                                                                                      ifCacheLocationIsKnown: cacheLocation,
                                                                                      ifResourceTypeIsKnown: .video)
        
        switch resourceExistenceState {
        case .uncached:
            guard let temporaryUncachedFileURL = Celestial.shared.getTemporarilyCachedFileURL(for: sourceURL) else {
                return
            }
            
            prepareAndPossiblyCacheVideo(at: temporaryUncachedFileURL)
            
        case .cached:
            
            setupPlayerIfVideoHasBeenCached(from: sourceURL)
            
        case .currentlyDownloading:
            // Use thumbnail?
            Celestial.shared.mergeExistingDownloadTask(with: downloadTaskRequest)
            
        case .downloadPaused:
            // Use thumbnail?
            Celestial.shared.resumeDownload(downloadTaskRequest: downloadTaskRequest)
            
        case .none:
            
            // Async load the video regardless of whether it has been cached,
            // due to the creation of AVURLAsset blocking main thread
            
            let assetKeys: [LoadableAssetKeys] = [.playable, .duration]
            DispatchQueue.global(qos: .userInitiated).async {
                AVURLAsset.prepareUsableAsset(withAssetKeys: assetKeys, inputURL: sourceURL) { [weak self] (playableAsset, error) in
                    guard let strongSelf = self else { return }
                    if let error = error {
                        fatalError("Error loading video from url: \(sourceURL). Error: \(String(describing: error))")
                    }
                    let playerItem = AVPlayerItem(asset: playableAsset)
                    DispatchQueue.main.async {
                        strongSelf.setupPlayer(with: playerItem)
                    }
                }
            }
                        
            if progressHandler != nil && completion != nil && progressHandler != nil {
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
            
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - No resource exists or is currently downloading for url: \(sourceURL). Will start new download")
            
            Celestial.shared.startDownload(downloadTaskRequest: downloadTaskRequest)
        }
    }
    
    private func setupPlayerIfVideoHasBeenCached(from sourceURL: URL) {
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - getting video from cache for url: \(sourceURL)")
        
        switch cacheLocation {
        case .inMemory:
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let strongSelf = self else { return }
                guard let memoryCachedVideoData = Celestial.shared.videoFromMemoryCache(sourceURLString: sourceURL.absoluteString) else {
                    return
                }
                
                let playerItem = DataLoadablePlayerItem(data: memoryCachedVideoData.videoData,
                                                        mimeType: memoryCachedVideoData.originalURLMimeType,
                                                        fileExtension: memoryCachedVideoData.originalURLFileExtension)
                
                DispatchQueue.main.async {
                    strongSelf.setupPlayer(with: playerItem)
                }
            }
            
        case .fileSystem:
            
            guard let cachedVideoURL = Celestial.shared.videoURLFromFileCache(sourceURL: sourceURL) else {
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                do {
                    let cachedVideoData = try Data(contentsOf: cachedVideoURL)
                    
                    DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Initializing DataLoadablePlayerItem with cached video url: \(cachedVideoURL). Media data size in MB: \(cachedVideoData.sizeInMB)")
                    
                    let playerItem = DataLoadablePlayerItem(data: cachedVideoData,
                                                            mimeType: cachedVideoURL.mimeType(),
                                                            fileExtension: cachedVideoURL.pathExtension)
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.setupPlayer(with: playerItem)
                    }
                    
                } catch let error {
                    DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error getting video data from url: \(sourceURL). Error: \(error)")
                }
            }
            
        default: break
        }
    }
    
    private func setupPlayer(with playerItem: AVPlayerItem) {
        let player = ObservableAVPlayer(playerItem: playerItem, delegate: self)
        player.isMuted = _isMuted
        super.player = player
    }
    
    public func play() {
        if super.player == nil {
            // Still waiting for DataLoadablePlayerItem to finish loading
            // or AVURLAsset to finish loading keys
            playImmediatelyWhenReady = true
        } else if super.player?.status == AVPlayer.Status.readyToPlay {
            super.player?.play()
        }
    }
    
    public func pause() {
        super.player?.pause()
    }
    
    public func reset() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            (strongSelf.player as? ObservableAVPlayer)?.reset()
            strongSelf.player?.pause()
            strongSelf.player = nil
        }
    }
}











// MARK: - CachableDownloadModelDelegate

extension URLVideoPlayerView: CachableDownloadModelDelegate {
    
    func cachable(_ downloadTaskRequest: DownloadTaskRequestProtocol, didFinishDownloadingTo intermediateTemporaryFileURL: URL) {
        
        prepareAndPossiblyCacheVideo(at: intermediateTemporaryFileURL)
    }
    
    func cachable(_ downloadTaskRequest: DownloadTaskRequestProtocol, downloadFailedWith error: Error) {
        if downloadTaskHandler != nil {
            // This is only called if `loadVideoFrom(urlString:, progressHandler:, completion:, errorHandler:)` was called.
            // In which case, this property will be non-nil
            downloadTaskHandler?.errorHandler?(error)
        } else {
            delegate?.urlCachableView?(self, downloadFailedWith: error)
        }
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

    
    
    
    
    
    private func prepareAndPossiblyCacheVideo(at intermediateTemporaryFileURL: URL) {
        
        guard let sourceURL = sourceURL else {
            return
        }
        
        switch cacheLocation {
        case .inMemory:
           
            Celestial.shared.decreaseVideoQuality(sourceURL: sourceURL, inputURL: intermediateTemporaryFileURL) { [weak self] (compressedVideoURL) in
                
                guard let compressedVideoURL = compressedVideoURL else {
                    return
                }
                
                do {
                    let compressedDownloadedMediaData = try Data(contentsOf: compressedVideoURL)
                    
                    DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Compressed video to \(compressedDownloadedMediaData.sizeInMB) MB")
                    
                    let videoData = MemoryCachedVideoData(videoData: compressedDownloadedMediaData,
                                                          originalURLMimeType: sourceURL.mimeType(),
                                                          originalURLFileExtension: sourceURL.pathExtension)
                    
                    Celestial.shared.storeVideoInMemoryCache(videoData: videoData, sourceURLString: sourceURL.absoluteString)
                    
                    self?.notifyReceiverOfDownloadCompletion(videoFileURL: compressedVideoURL)
                    
                } catch let error {
                    DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error getting data from contents of url: \(compressedVideoURL). Error: \(error)")
                }
            }
            
        case .fileSystem:
           
            Celestial.shared.storeDownloadedVideoToFileCache(intermediateTemporaryFileURL,
                                                             withSourceURL: sourceURL,
                                                             completion: { [weak self] (compressedVideoURL) in
                                                                
                guard let compressedVideoURL = compressedVideoURL else {
                    return
                }
                                                                
                self?.notifyReceiverOfDownloadCompletion(videoFileURL: compressedVideoURL)
            })
            
        default:
            
            Celestial.shared.deleteFile(at: intermediateTemporaryFileURL)
            
            notifyReceiverOfDownloadCompletion(videoFileURL: intermediateTemporaryFileURL)
        }
    }
    
    private func notifyReceiverOfDownloadCompletion(videoFileURL: URL) {
        if downloadTaskHandler != nil {
            // This is only called if `loadImageFrom(urlString:, progressHandler:, completion:, errorHandler:)` was called.
            // In which case, this property will be non-nil
            downloadTaskHandler?.completionHandler?(videoFileURL)
        } else {
            
            delegate?.urlCachableView?(self, didFinishDownloading: videoFileURL)
        }
    }
}











// MARK: - ObservableAVPlayerDelegate

extension URLVideoPlayerView: ObservableAVPlayerDelegate {
    
    func observablePlayer(_ player: ObservableAVPlayer, didLoadChangePlayerItem status: AVPlayerItem.Status) {
        // Switch over the status
        switch status {
        case .readyToPlay:
            // Player item is ready to play.
            
            delegate?.urlVideoPlayerIsReadyToPlay?(self)
            
            if playImmediatelyWhenReady {
                play()
            }
            
        case .failed:
            // Player item failed. See error.
            break
        case .unknown:
            // Player item is not yet ready.
            break
        @unknown default:
            fatalError()
        }
    }
}
