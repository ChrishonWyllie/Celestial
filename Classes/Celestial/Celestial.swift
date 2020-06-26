//
//  Celestial.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import UIKit

public final class Celestial: NSObject {
    
    /// Public shared instance property
    public static let shared = Celestial()
    
    internal var debugModeIsActive: Bool = false
    
    
    
    
    // MARK: - Initializers
    
    private override init() {
        super.init()
    }
}





// MARK: -  MemoryCacheProtocol

extension Celestial: CelestialCacheProtocol {
    
    public func videoExists(for sourceURL: URL, cacheLocation: DownloadCompletionCacheLocation) -> Bool {
        switch cacheLocation {
        case .inMemory:
            return videoData(for: sourceURL.absoluteString) != nil
        case .fileSystem:
            return FileStorageManager.shared.videoExists(for: sourceURL)
        }
    }
    
    public func videoData(for sourceURLString: String) -> MemoryCachedVideoData? {
        return VideoCache.shared.item(for: sourceURLString)
    }
    
    public func videoURL(for sourceURL: URL, resolution: CGSize) -> URL? {
        return FileStorageManager.shared.getCachedVideoURL(for: sourceURL, resolution: resolution)
    }

    public func store(videoData: MemoryCachedVideoData?, with sourceURLString: String) {
        VideoCache.shared.store(videoData, with: sourceURLString)
    }
    
    public func storeVideoURL(_ videoURL: URL, withSourceURL sourceURL: URL, resolution: CGSize, completion: @escaping (URL?) -> ()) {
        FileStorageManager.shared.cachedAndResizedVideo(sourceURL: sourceURL, resolution: resolution, intermediateTemporaryFileURL: videoURL, completion: completion)
    }
    
    
    public func removeVideoData(using sourceURLString: String) {
        VideoCache.shared.removeItem(at: sourceURLString)
    }
    
    public func removeVideoURL(using sourceURL: URL) -> Bool {
        return FileStorageManager.shared.deleteCachedVideo(using: sourceURL)
    }
    
    public func clearAllVideos() {
        VideoCache.shared.clearAllItems()
        FileStorageManager.shared.clearCache(FileStorageManager.CacheClearingStyle.videos)
    }
    
    
    
    
    
    

    
    
    
    
    
    
    
    
    
    public func imageExists(for sourceURL: URL, cacheLocation: DownloadCompletionCacheLocation) -> Bool {
        switch cacheLocation {
        case .inMemory:
            return image(for: sourceURL.absoluteString) != nil
        case .fileSystem:
            return FileStorageManager.shared.imageExists(for: sourceURL)
        }
    }
    
    public func image(for sourceURLString: String) -> UIImage? {
        return ImageCache.shared.item(for: sourceURLString)
    }
    
    public func imageURL(for sourceURL: URL, pointSize: CGSize) -> URL? {
        return FileStorageManager.shared.getCachedImageURL(for: sourceURL, size: pointSize)
    }
    
    public func store(image: UIImage?, with sourceURLString: String) {
        ImageCache.shared.store(image, with: sourceURLString)
    }
    
    public func storeImageURL(_ imageURL: URL, withSourceURL sourceURL: URL, pointSize: CGSize) -> UIImage? {
        return FileStorageManager.shared.cachedAndResizedImage(sourceURL: sourceURL, size: pointSize, intermediateTemporaryFileURL: imageURL)
    }
    
    public func removeImage(using sourceURLString: String) {
        ImageCache.shared.removeItem(at: sourceURLString)
    }
    
    public func removeImageURL(using sourceURL: URL) -> Bool {
        return FileStorageManager.shared.deleteCachedImage(using: sourceURL)
    }
    
    public func clearAllImages() {
        ImageCache.shared.clearAllItems()
        FileStorageManager.shared.clearCache(FileStorageManager.CacheClearingStyle.images)
    }
    
    
    
    
    
    
    
    
    
    
    // MISC.
    
    func setCacheItemLimit(videoCache: Int?, imageCache: Int?) {
        if let videoCacheLimit = videoCache {
            VideoCache.shared.setCacheItemLimit(videoCacheLimit)
        }
        if let imageCacheLimit = imageCache {
            ImageCache.shared.setCacheItemLimit(imageCacheLimit)
        }
    }
    
    public func setCacheCostLimit(videoCache: Int?, imageCache: Int?) {
        if let videoCacheLimit = videoCache {
            VideoCache.shared.setCacheCostLimit(numMegabytes: videoCacheLimit)
        }
        if let imageCacheLimit = imageCache {
            ImageCache.shared.setCacheCostLimit(numMegabytes: imageCacheLimit)
        }
    }
    
    public func setDebugMode(on: Bool) {
        debugModeIsActive = on
    }
    
    public func reset() {
        clearAllImages()
        clearAllVideos()
    }
}
