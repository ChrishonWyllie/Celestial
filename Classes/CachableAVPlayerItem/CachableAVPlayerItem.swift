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
    
    private let resourceLoaderDelegate = ResourceLoaderDelegate()
    private var initialScheme: String?
    private var customFileExtension: String?
    private let cachableAVPlayerItemScheme = "cachableAVPlayerItemScheme"
    
    
    
    
    
    
    
    
    
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
        
        var asset: AVURLAsset
        
        if let originalVideoData = Celestial.shared.video(for: url.absoluteString) {
            guard let fakeUrl = URL(string: cachableAVPlayerItemScheme + "://whatever/file.\(originalVideoData.originalURLFileExtension)") else {
                fatalError("internal inconsistency")
            }
            
            self.url = fakeUrl
            self.initialScheme = nil
            
            resourceLoaderDelegate.setMediaData(originalVideoData.videoData, mimeType: originalVideoData.originalURLMimeType)
            
            asset = AVURLAsset(url: fakeUrl)
        } else {
            
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                let scheme = components.scheme,
                var urlWithCustomScheme = url.withScheme(cachableAVPlayerItemScheme) else {
                fatalError("Urls without a scheme are not supported")
            }
            
            self.url = url
            self.delegate = delegate
            self.cachePolicy = cachePolicy
            self.initialScheme = scheme
            
            if let ext = customFileExtension {
                urlWithCustomScheme.deletePathExtension()
                urlWithCustomScheme.appendPathExtension(ext)
                self.customFileExtension = ext
            }
            
            asset = AVURLAsset(url: urlWithCustomScheme)
        }
        
        
        
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        
        resourceLoaderDelegate.setCachableAVPlayerItem(to: self)
        
        setupNotificationObservers()
        
    }
    
    /// Is used for playing from Data.
    public init(data: Data, mimeType: String, fileExtension: String) {
        
        guard let fakeUrl = URL(string: cachableAVPlayerItemScheme + "://whatever/file.\(fileExtension)") else {
            fatalError("internal inconsistency")
        }
        
        self.url = fakeUrl
        self.initialScheme = nil
        
        resourceLoaderDelegate.setMediaData(data, mimeType: mimeType)
        
        let asset = AVURLAsset(url: fakeUrl)
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        
        resourceLoaderDelegate.setCachableAVPlayerItem(to: self)
        
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playbackStalledHandler),
                                               name: NSNotification.Name.AVPlayerItemPlaybackStalled,
                                               object: self)
    }
    
    override init(asset: AVAsset, automaticallyLoadedAssetKeys: [String]?) {
        fatalError("not implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        removeObserver(self, forKeyPath: "status")
        resourceLoaderDelegate.session?.invalidateAndCancel()
    }
    
    
    
    
    
    
    
    // MARK: - Functions
    
    public func download() {
        if resourceLoaderDelegate.session == nil {
            resourceLoaderDelegate.startDataRequest(with: url)
        }
    }
    
    
    
    
    
    // MARK: KVO
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        delegate?.playerItemReadyToPlay?(self)
    }
    
    // MARK: Notification handlers
    
    @objc private func playbackStalledHandler() {
        delegate?.playerItemPlaybackStalled?(self)
    }

}
