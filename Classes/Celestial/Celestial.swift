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






// MARK: - Video

extension Celestial: CelestialVideoCachingProtocol {
    
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
   
    public func videoURL(for sourceURL: URL) -> URL? {
        return FileStorageManager.shared.getCachedVideoURL(for: sourceURL)
    }

    public func store(videoData: MemoryCachedVideoData?, with sourceURLString: String) {
        VideoCache.shared.store(videoData, with: sourceURLString)
    }
   
    public func storeVideoURL(_ videoURL: URL, withSourceURL sourceURL: URL, completion: @escaping (URL?) -> ()) {
        FileStorageManager.shared.cachedAndResizedVideo(sourceURL: sourceURL, intermediateTemporaryFileURL: videoURL, completion: completion)
    }
   
    public func removeVideoData(using sourceURLString: String) {
        VideoCache.shared.removeItem(at: sourceURLString)
    }
   
    public func removeVideoURL(using sourceURL: URL) -> Bool {
        return FileStorageManager.shared.deleteCachedVideo(using: sourceURL)
    }
   
    public func clearAllVideos() {
        VideoCache.shared.clearAllItems()
        FileStorageManager.shared.clearCache(fileType: Celestial.ResourceFileType.video)
    }
}



// MARK: - Image

extension Celestial: CelestialImageCachingProtocol {
    
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
        FileStorageManager.shared.clearCache(fileType: Celestial.ResourceFileType.image)
    }
}




// MARK: - Downloads

extension Celestial: CelestialResourcePrefetchingProtocol {
    
    public func downloadState(for sourceURL: URL) -> DownloadTaskState {
        return DownloadTaskManager.shared.downloadState(for: sourceURL)
    }
    
    public func startDownload(for sourceURL: URL) {
        // downloadModel will be exchanged with non-nil delegate when view
        // calls load(urlString:)
        let downloadModel = GenericDownloadModel(sourceURL: sourceURL, delegate: nil)
        DownloadTaskManager.shared.startDownload(model: downloadModel)
    }
    
    public func pauseDownload(for sourceURL: URL) {
        DownloadTaskManager.shared.pauseDownload(for: sourceURL)
    }
    
    public func resumeDownload(for sourceURL: URL) {
        DownloadTaskManager.shared.resumeDownload(for: sourceURL)
    }
    
    public func cancelDownload(for sourceURL: URL) {
        DownloadTaskManager.shared.cancelDownload(for: sourceURL)
    }
    
    internal func resourceExistenceState(for sourceURL: URL,
                                         cacheLocation: DownloadCompletionCacheLocation,
                                         fileType: Celestial.ResourceFileType) -> ResourceExistenceState {
        switch fileType {
        case .video:
            
            if FileStorageManager.shared.uncachedFileExists(for: sourceURL)
                && FileStorageManager.shared.videoExists(for: sourceURL) == false {
                return .uncached
            }
            
            if videoExists(for: sourceURL, cacheLocation: cacheLocation) {
                return .cached
            }
            
        case .image:
            
            if FileStorageManager.shared.uncachedFileExists(for: sourceURL)
                && FileStorageManager.shared.imageExists(for: sourceURL) == false {
                return .uncached
            }
            
            if imageExists(for: sourceURL, cacheLocation: cacheLocation) {
                return .cached
            }
            
        default:
            fatalError("Unsupported file type: \(fileType)")
        }
        
        switch downloadState(for: sourceURL) {
        case .downloading: return .currentlyDownloading
        case .paused: return .downloadPaused
        case .none: return .none
        default: fatalError("The download is simultaneously finished but uncached")
        }
    }
    
    /// Determines what state a resource is in
    /// Whether it has been cached, exists in a temporary uncached state, currently
    internal enum ResourceExistenceState: Int {
        /// The resource has completed downloading but remains in a temporary
        /// cache in the file system until URLCachableView decides what to do with it
        case uncached = 0
        /// The resource has completed downloading and is cached to either memory or file system
        case cached
        /// The resource is currently being downloaded
        case currentlyDownloading
        /// The download task for the resource has been paused
        case downloadPaused
        /// There are no pending downloads for the resource, nor does it exist anywhere. Must begin new download
        case none
    }

    internal enum ResourceFileType {
        case video
        case image
        case temporary
        case all
    }
}







// MARK: - MemoryCache

extension Celestial: CelestialMemoryCacheProtocol {
    
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
}










// MARK: - Utility

extension Celestial: CelestialUtilityProtocol {
    
    public func setDebugMode(on: Bool) {
        debugModeIsActive = on
    }
       
    public func reset() {
        clearAllImages()
        clearAllVideos()
    }
    
    public func getCacheInfo() -> [String] {
        return FileStorageManager.shared.getCacheInfo().map { "\n\($0)" }
    }
}
