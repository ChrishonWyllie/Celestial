//
//  CachableAVPlayerItem.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/28/19.
//

import Foundation
import AVFoundation

/// Subclass of AVPlayerItem which can download and display a video from an external URL,
/// then cache it for future use if desired.
/// This is used together with the Celestial cache to prevent needless downloading of the same videos.
open class CachableAVPlayerItem: AVPlayerItem {
    
    // MARK: - Variables
    
    public private(set) var url: URL
    public private(set) var cachePolicy: MultimediaCachePolicy = .allow
    public private(set) weak var delegate: CachableAVPlayerItemDelegate?
    
    private var assetResourceLoader: MediaResourceLoader?
    private var initialScheme: String?
    private var customFileExtension: String?
    private let cachableAVPlayerItemScheme = "cachableAVPlayerItemScheme"
    
    // Key-value observing context
    private var playerItemContext = 0
    
    let requiredAssetKeys = [
        "playable",
        "hasProtectedContent"
    ]
    
    
    
    
    
    
    
    // MARK: - Initializers
    
    /// Convenience initializer used for playing remote files.
    /// NOTE: Your should use this as primary method of initialization.
    /// - Parameter url: The URL of the video you would like to download and play
    /// - Parameter delegate: `CachableAVPlayerItemDelegate` for useful delegation functions such as knowing when download has completed, or its current progress.
    /// - Parameter cachePolicy: `MultimediaCachePolicy` for determining whether the video should be cached upon completion of its download.
    convenience public init(url: URL, delegate: CachableAVPlayerItemDelegate?, cachePolicy: MultimediaCachePolicy = .allow) {
        self.init(url: url, customFileExtension: nil, delegate: delegate, cachePolicy: cachePolicy)
    }
    
    /// Override/append custom file extension to URL path.
    /// This is required for the player to work correctly with the intended file type.
    public init(url: URL, customFileExtension: String?, delegate: CachableAVPlayerItemDelegate?, cachePolicy: MultimediaCachePolicy = .allow) {
        
        self.url = url
        self.delegate = delegate
        self.cachePolicy = cachePolicy
        
        var asset: AVURLAsset
        
        if let originalVideoData = Celestial.shared.videoData(for: url.absoluteString) {
            let fakeURLString = cachableAVPlayerItemScheme + "://whatever/file.\(originalVideoData.originalURLFileExtension)"
            guard let fakeUrl = URL(string: fakeURLString) else {
                fatalError("internal inconsistency")
            }
            
            initialScheme = nil
            
            assetResourceLoader = MediaResourceLoader(url: url)
            assetResourceLoader?.setMediaData(originalVideoData.videoData, mimeType: originalVideoData.originalURLMimeType)

            asset = AVURLAsset(url: fakeUrl)
        } else {
            
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                let scheme = components.scheme,
                var urlWithCustomScheme = url.withScheme(cachableAVPlayerItemScheme) else {
                fatalError("Urls without a scheme are not supported")
            }
            
            initialScheme = scheme

            assetResourceLoader = MediaResourceLoader(url: url)

            if let ext = customFileExtension {
                urlWithCustomScheme.deletePathExtension()
                urlWithCustomScheme.appendPathExtension(ext)
                self.customFileExtension = ext
            }

            asset = AVURLAsset(url: urlWithCustomScheme)
        }
        
        
        asset.resourceLoader.setDelegate(assetResourceLoader, queue: DispatchQueue.main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: requiredAssetKeys)
        
        assetResourceLoader?.delegate = self
        
        setupNotificationObservers()
        
    }
    
    /// Is used for playing from Data.
    public init(data: Data, mimeType: String, fileExtension: String) {
        
        let fakeURLString = cachableAVPlayerItemScheme + "://whatever/file.\(fileExtension)"
        guard let fakeUrl = URL(string: fakeURLString) else {
            fatalError("internal inconsistency")
        }
        
        self.url = fakeUrl
        self.initialScheme = nil
        assetResourceLoader = MediaResourceLoader()
        assetResourceLoader?.setMediaData(data, mimeType: mimeType)
        
        let asset = AVURLAsset(url: fakeUrl)
        asset.resourceLoader.setDelegate(assetResourceLoader, queue: DispatchQueue.main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: requiredAssetKeys)
        
        assetResourceLoader?.delegate = self
        
        setupNotificationObservers()
    }
    
    override init(asset: AVAsset, automaticallyLoadedAssetKeys: [String]?) {
        fatalError("not implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        assetResourceLoader?.clear()
    }
    
    
    // MARK: - Functions
    
    private func setupNotificationObservers() {
        addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &playerItemContext)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playbackStalledHandler),
                                               name: NSNotification.Name.AVPlayerItemPlaybackStalled,
                                               object: self)
    }
    
    public func download() {
        if assetResourceLoader?.session == nil {
            assetResourceLoader?.startDataRequest(with: url)
        }
    }
    
    
    
    
    
    // MARK: KVO
    
    override open func observeValue(forKeyPath keyPath: String?,
                                    of object: Any?,
                                    change: [NSKeyValueChangeKey : Any]?,
                                    context: UnsafeMutableRawPointer?) {

        // Only handle observations for the playerItemContext
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
        }

        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }

            // Switch over status value
            switch status {
            case .readyToPlay:
                delegate?.playerItemReadyToPlay?(self)
            case .failed:
                // Player item failed. See error.
                if let error = error {
                    delegate?.playerItem?(self, failedToPlayWith: error)
                }
            case .unknown:
                // Player item is not yet ready.
                break
            @unknown default:
                fatalError("New AVPlayerItem.Status has been introduced")
            }
        }
    }
    
    // MARK: Notification handlers
    
    @objc private func playbackStalledHandler() {
        delegate?.playerItemPlaybackStalled?(self)
    }

}










// MARK: - MediaResourceLoaderDelegate

extension CachableAVPlayerItem: MediaResourceLoaderDelegate {
    
    func resourceLoader(_ loader: MediaResourceLoader, didFinishDownloading media: Any) {
        guard let mediaData = media as? Data else {
            fatalError()
        }
        
        guard let sourceURL = loader.initialURL else {
            return
        }

        let originalVideoData = MemoryCachedVideoData(videoData: mediaData,
                                                  originalURLMimeType: sourceURL.mimeType(),
                                                  originalURLFileExtension: sourceURL.pathExtension)
        if self.cachePolicy == .allow {
            Celestial.shared.store(videoData: originalVideoData, with: sourceURL.absoluteString)
        }
        
        delegate?.playerItem(self, didFinishDownloading: mediaData)
    }
    
    func resourceLoader(_ loader: MediaResourceLoader, downloadFailedWith error: Error) {
        delegate?.playerItem(self, downloadFailedWith: error)
    }
    
    func resourceLoader(_ loader: MediaResourceLoader, downloadProgress progress: CGFloat, humanReadableProgress: String) {
        delegate?.playerItem?(self, downloadProgress: progress, humanReadableProgress: humanReadableProgress)
    }
    
}
