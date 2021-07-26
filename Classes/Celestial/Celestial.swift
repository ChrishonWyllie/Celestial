//
//  Celestial.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import UIKit

public final class Celestial: NSObject {
    
    enum CSError: Error {
        case invalidURL(String)
        case urlToDataError(String)
        case invalidSourceURLError(String)
        case unknownURLPathExtension(String)
    }
    
    /// Public shared instance property
    public static let shared = Celestial()
    
    internal var debugModeIsActive: Bool = false
    
    internal let cachedResourceContext = CachedResourceIdentifierContext()
    
    private var backgroundSessionCompletionHandler: (() -> Void)?
    
    /**
     Defines the quality at which a downloaded video will be compressed to
     
     - The `default` option will not compress, and will cache the video using its original file size / resolution.
     - The `low` and `medium` options may be used to cache lower quality versions of a video once its download completes
     */
    public enum VideoExportQuality {
        case `default`
        case low
        case medium
    }
    
    
    
    
    // MARK: - Initializers
    
    private override init() {
        super.init()
        
    }
}






// MARK: - Video

extension Celestial: CelestialVideoCachingProtocol {
    
    public func videoExists(for sourceURL: URL, cacheLocation: ResourceCacheLocation) -> Bool {
        return cachedResourceAndIdentifierExists(for: sourceURL, resourceType: .video, cacheLocation: cacheLocation)
    }
   
    public func videoFromMemoryCache(sourceURLString: String) -> MemoryCachedVideoData? {
        if let sourceURL = URL(string: sourceURLString){
            return VideoCache.shared.item(for: sourceURL.lastPathComponent.convertURLToUniqueFileName())
        }
        return nil
    }
   
    public func videoURLFromFileCache(sourceURL: URL) -> URL? {
        return FileStorageManager.shared.getCachedVideoURL(for: sourceURL)
    }

    public func storeVideoInMemoryCache(videoData: MemoryCachedVideoData?, sourceURLString: String) {
        guard
            sourceURLString.isValidURL,
            let sourceURL = URL(string: sourceURLString) else {
            fatalError("\(sourceURLString) is not a valid URL")
        }
        let resourceIdentifier = CachedResourceIdentifier(sourceURL: sourceURL,
                                                          resourceType: .video,
                                                          cacheLocation: .inMemory)
        cachedResourceContext.storeReferenceTo(cachedResource: resourceIdentifier)
        VideoCache.shared.store(videoData, with: sourceURL.lastPathComponent.convertURLToUniqueFileName())
    }
   
    public func storeDownloadedVideoToFileCache(_ temporaryFileURL: URL, withSourceURL sourceURL: URL, videoExportQuality: Celestial.VideoExportQuality, completion: @escaping MediaAssetCompletionHandler) {
        FileStorageManager.shared.cacheVideo(withSourceURL: sourceURL, intermediateTemporaryFileURL: temporaryFileURL, videoExportQuality: videoExportQuality) { [weak self] (cachedVideoURL, error) in
            
            let resourceIdentifier = CachedResourceIdentifier(sourceURL: sourceURL,
                                                              resourceType: .video,
                                                              cacheLocation: .fileSystem)
            self?.cachedResourceContext.storeReferenceTo(cachedResource: resourceIdentifier)
            
            completion(cachedVideoURL, error)
        }
    }
    
    public func decreaseVideoQuality(intermediateFileURL: URL, withSourceURL sourceURL: URL, toQuality videoExportQuality: Celestial.VideoExportQuality, completion: @escaping MediaAssetCompletionHandler) {
        FileStorageManager.shared.decreaseVideoQuality(intermediateFileURL: intermediateFileURL, withSourceURL: sourceURL, toQuality: videoExportQuality, completion: completion)
    }
    
    public func removeVideoFromMemoryCache(sourceURLString: String) {
        if let sourceURL = URL(string: sourceURLString){
            VideoCache.shared.removeItem(at: sourceURL.lastPathComponent.convertURLToUniqueFileName())
            cachedResourceContext.removeResourceIdentifier(for: sourceURLString)
        }
    }
   
    @discardableResult public func removeVideoFromFileCache(sourceURLString: String) -> Bool {
        guard
            sourceURLString.isValidURL,
            let sourceURL = URL(string: sourceURLString) else {
            fatalError("\(sourceURLString) is not a valid URL")
        }
        let successfullyDeletedResource = FileStorageManager.shared.deleteCachedVideo(using: sourceURL)
        if successfullyDeletedResource {
            cachedResourceContext.removeResourceIdentifier(for: sourceURLString)
        }
        return successfullyDeletedResource
    }
   
    public func clearAllVideos() {
        cachedResourceContext.clearResourceIdentifiers(withResourceType: .video)
        VideoCache.shared.clearAllItems()
        FileStorageManager.shared.clearCache(fileType: ResourceFileType.video)
    }
}



// MARK: - Image

extension Celestial: CelestialImageCachingProtocol {
    
    public func imageExists(for sourceURL: URL, cacheLocation: ResourceCacheLocation) -> Bool {
        return cachedResourceAndIdentifierExists(for: sourceURL, resourceType: .image, cacheLocation: cacheLocation)
    }
    
    public func imageFromMemoryCache(sourceURLString: String) -> UIImage? {
        if let sourceURL = URL(string: sourceURLString){
            return ImageCache.shared.item(for: sourceURL.lastPathComponent.convertURLToUniqueFileName())
        }
        return nil
    }
    
    public func imageURLFromFileCache(sourceURL: URL, pointSize: CGSize) -> URL? {
        return FileStorageManager.shared.getCachedImageURL(for: sourceURL, size: pointSize)
    }
    
    public func storeImageInMemoryCache(image: UIImage?, sourceURLString: String) {
        guard
            sourceURLString.isValidURL,
            let sourceURL = URL(string: sourceURLString) else {
            fatalError("\(sourceURLString) is not a valid URL")
        }
        let resourceIdentifier = CachedResourceIdentifier(sourceURL: sourceURL,
                                                          resourceType: .image,
                                                          cacheLocation: .inMemory)
        cachedResourceContext.storeReferenceTo(cachedResource: resourceIdentifier)
        ImageCache.shared.store(image, with: sourceURL.lastPathComponent.convertURLToUniqueFileName())
    }
    
    public func storeDownloadedImageToFileCache(_ temporaryFileURL: URL, withSourceURL sourceURL: URL, pointSize: CGSize, completion: @escaping (UIImage?) -> ()) {
        
        FileStorageManager.shared.cachedAndResizedImage(sourceURL: sourceURL, size: pointSize, intermediateTemporaryFileURL: temporaryFileURL, completion: { [weak self] (cachedImageURL) in
            
            let resourceIdentifier = CachedResourceIdentifier(sourceURL: sourceURL,
                                                              resourceType: .image,
                                                              cacheLocation: .fileSystem)
            self?.cachedResourceContext.storeReferenceTo(cachedResource: resourceIdentifier)
            
            completion(cachedImageURL)
        })
    }
    
    public func removeImageFromMemoryCache(sourceURLString: String) {
        ImageCache.shared.removeItem(at: sourceURLString)
        cachedResourceContext.removeResourceIdentifier(for: sourceURLString)
    }
    
    @discardableResult public func removeImageFromFileCache(sourceURLString: String) -> Bool {
        
        guard
            sourceURLString.isValidURL,
            let sourceURL = URL(string: sourceURLString) else {
            fatalError("\(sourceURLString) is not a valid URL")
        }
        let successfullyDeletedResource = FileStorageManager.shared.deleteCachedImage(using: sourceURL)
        if successfullyDeletedResource {
            cachedResourceContext.removeResourceIdentifier(for: sourceURLString)
        }
        return successfullyDeletedResource
    }
    
    public func clearAllImages() {
        cachedResourceContext.clearResourceIdentifiers(withResourceType: .image)
        ImageCache.shared.clearAllItems()
        FileStorageManager.shared.clearCache(fileType: ResourceFileType.image)
    }
}




// MARK: - Downloads

extension Celestial: CelestialResourcePrefetchingProtocol {
    
    public func downloadState(for sourceURL: URL) -> DownloadTaskState {
        return DownloadTaskManager.shared.downloadState(forSourceURL: sourceURL)
    }
    
    public func startDownload(for sourceURL: URL) {
        // downloadTaskRequest will be exchanged with non-nil delegate when view
        // calls load(urlString:)
        let downloadTaskRequest = DownloadTaskRequest(sourceURL: sourceURL, delegate: nil)
        DownloadTaskManager.shared.startDownload(downloadTaskRequest: downloadTaskRequest)
    }
    
    public func pauseDownload(for sourceURL: URL) {
        DownloadTaskManager.shared.pauseDownload(forSourceURL: sourceURL)
    }
    
    public func resumeDownload(for sourceURL: URL) {
        DownloadTaskManager.shared.resumeDownload(forSourceURL: sourceURL)
    }
    
    public func cancelDownload(for sourceURL: URL) {
        DownloadTaskManager.shared.cancelDownload(forSourceURL: sourceURL)
    }
    
    public func prefetchResources(at urlStrings: [String]) {
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.handleScrollViewPrefetching(forRequestedItems: urlStrings) { (sourceURL, resourceExistenceState) in
                
                switch resourceExistenceState {
                case .none:
                    strongSelf.startDownload(for: sourceURL)
                case .downloadPaused:
                    strongSelf.resumeDownload(for: sourceURL)
                case .currentlyDownloading, .cached, .uncached:
                    // Nothing more to do
                    break
                }
            }
        }
    }
    
    public func pausePrefetchingForResources(at urlStrings: [String], cancelCompletely: Bool) {
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.handleScrollViewPrefetching(forRequestedItems: urlStrings) { (sourceURL, resourceExistenceState) in
                
                switch resourceExistenceState {
                case .none, .downloadPaused, .cached, .uncached:
                    // Nothing more to do
                    break
                case .currentlyDownloading:
                    if cancelCompletely {
                        strongSelf.cancelDownload(for: sourceURL)
                    } else {
                        strongSelf.pauseDownload(for: sourceURL)
                    }
                }
            }
        }
    }
    
    private func handleScrollViewPrefetching(forRequestedItems urlStrings: [String], performSomeOpertionUsingURL: @escaping (URL, ResourceExistenceState) -> ()) {
        for sourceURLString in urlStrings {
        
            guard
                sourceURLString.isValidURL,
                let sourceURL = URL(string: sourceURLString) else {
                fatalError("\(sourceURLString) is not a valid URL")
            }
            
            let resourceExistenceState = determineResourceExistenceState(forSourceURL: sourceURL,
                                                                         ifCacheLocationIsKnown: nil,
                                                                         ifResourceTypeIsKnown: nil)
            
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Handling prefetch for url: \(sourceURL), resource existence state: \(String(reflecting: resourceExistenceState))")
            
            performSomeOpertionUsingURL(sourceURL, resourceExistenceState)
        }
    }
}







// MARK: - MemoryCache

extension Celestial: CelestialMemoryCacheProtocol {
    
    public func setMemoryCacheItemLimits(videoCache: Int? = nil, imageCache: Int? = nil) {
        if let videoCacheLimit = videoCache {
            VideoCache.shared.setCacheItemLimit(videoCacheLimit)
        }
        if let imageCacheLimit = imageCache {
            ImageCache.shared.setCacheItemLimit(imageCacheLimit)
        }
    }
    
    public func setMemoryCacheCostLimits(videoCache: Int? = nil, imageCache: Int? = nil) {
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
        FileStorageManager.shared.clearCache(fileType: ResourceFileType.all)
        DownloadTaskManager.shared.cancelAllDownloads()
        cachedResourceContext.clearAllResourceIdentifiers()
        VideoCache.shared.clearAllItems()
        ImageCache.shared.clearAllItems()
    }
    
    public func getCacheInfo() -> [String] {
        return FileStorageManager.shared.getCacheInfo().map { "\n\($0)" }
    }
    
    
    
    
    
    
    internal func mergeExistingDownloadTask(with newDownloadTask: DownloadTaskRequest) {
        DownloadTaskManager.shared.mergeExistingDownloadTask(with: newDownloadTask)
    }
    
    internal func resumeDownload(downloadTaskRequest: DownloadTaskRequest) {
        DownloadTaskManager.shared.resumeDownload(downloadTaskRequest: downloadTaskRequest)
    }
    
    internal func startDownload(downloadTaskRequest: DownloadTaskRequest) {
        DownloadTaskManager.shared.startDownload(downloadTaskRequest: downloadTaskRequest)
    }
    
    internal func deleteFile(at location: URL, deleteReferenceForSourceURL url: URL? = nil) {
        if let sourceURL = url {
            cachedResourceContext.removeResourceIdentifier(for: sourceURL.absoluteString)
        }
        DispatchQueue.global(qos: .utility).async {
            FileStorageManager.shared.deleteFile(at: location)
        }
    }
    
    internal func getTemporarilyCachedFileURL(for sourceURL: URL) -> URL? {
        return FileStorageManager.shared.getTemporarilyCachedFileURL(for: sourceURL)
    }
}

















// MARK: - CachedResourceIdentifier

extension Celestial {
    
    func determineResourceExistenceState(forSourceURL sourceURL: URL,
                                         ifCacheLocationIsKnown cacheLocation: ResourceCacheLocation?,
                                         ifResourceTypeIsKnown resourceType: ResourceFileType?) -> ResourceExistenceState {
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Determining resource existence state for source url: \(sourceURL)")
        
        if cacheLocation == nil || resourceType == nil {
            if videoExists(for: sourceURL, cacheLocation: .inMemory)
                || videoExists(for: sourceURL, cacheLocation: .fileSystem)
                || imageExists(for: sourceURL, cacheLocation: .inMemory)
                || imageExists(for: sourceURL, cacheLocation: .fileSystem)
            {
                return .cached
            } else {
                if FileStorageManager.shared.uncachedFileExists(for: sourceURL) {
                    return .uncached
                }
                return .none
            }
        } else if let cacheLocation = cacheLocation, let resourceType = resourceType {
            if cachedResourceAndIdentifierExists(for: sourceURL, resourceType: resourceType, cacheLocation: cacheLocation) {
                return .cached
            } else {
                if FileStorageManager.shared.uncachedFileExists(for: sourceURL) {
                    return .uncached
                }
                return .none
            }
        } else if FileStorageManager.shared.uncachedFileExists(for: sourceURL) {
            return .uncached
        } else {
            switch downloadState(for: sourceURL) {
            case .none: return .none
            case .paused: return .downloadPaused
            case .downloading: return .currentlyDownloading
            case .finished:
                
                DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Determining resource existence state for source url: \(sourceURL)")
                
                if videoExists(for: sourceURL, cacheLocation: .fileSystem) && cacheLocation == .inMemory
                    || videoExists(for: sourceURL, cacheLocation: .inMemory) && cacheLocation == .fileSystem
                    || imageExists(for: sourceURL, cacheLocation: .fileSystem) && cacheLocation == .inMemory
                    || imageExists(for: sourceURL, cacheLocation: .inMemory) && cacheLocation == .fileSystem
                {
                    
                    /*
                     Represents an unusual case:
                     The image exists in file system, but the request for this image
                     expects it to be in memory (local NSCache)
                     Or vice versa
                     In this case, return .none for the file does not exist here
                     */
                    return .none
                }
                
                fatalError("Unknown existence state for resource at source URL: \(sourceURL)")
            }
        }
    }
    
    private func cachedResourceAndIdentifierExists(for sourceURL: URL, resourceType: ResourceFileType, cacheLocation: ResourceCacheLocation) -> Bool {
        var identifierExists = cachedResourceContext.resourceIdentifierExists(for: sourceURL)
        var fileExists: Bool = false
        
        switch cacheLocation {
        case .inMemory:
            switch resourceType {
            case .video:
                fileExists = videoFromMemoryCache(sourceURLString: sourceURL.absoluteString) != nil
            case .image:
                fileExists = imageFromMemoryCache(sourceURLString: sourceURL.absoluteString) != nil
            default: fatalError("Unexpected resource type: \(String(reflecting: resourceType))")
            }
        case .fileSystem:
            switch resourceType {
            case .video:
                fileExists = videoURLFromFileCache(sourceURL: sourceURL) != nil
            case .image:
                fileExists = FileStorageManager.shared.imageExists(for: sourceURL)
            default: fatalError("Unexpected resource type: \(String(reflecting: resourceType))")
            }
        case .none:
            return false
        }
        
        if identifierExists == false && fileExists == true {
            let resourceIdentifier = CachedResourceIdentifier(sourceURL: sourceURL, resourceType: resourceType, cacheLocation: cacheLocation)
            cachedResourceContext.storeReferenceTo(cachedResource: resourceIdentifier)
            identifierExists = true
        }
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Checking if cached resource exists for source url: \(sourceURL). local unique identifier: \(sourceURL.localUniqueFileName()). identifier exists: \(identifierExists). file exists: \(fileExists)")
        
        return identifierExists && fileExists
    }
}














// MARK: - BackgroundSession

extension Celestial {
    
    public func handleBackgroundSession(identifier: String, completionHandler: @escaping () -> Void) {
        guard identifier == DownloadTaskManager.backgroundDownloadSessionIdentifier else {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Found another identifier: \(identifier)")
            return
        }
        backgroundSessionCompletionHandler = completionHandler
    }
    
    internal func completeBackgroundSession() {
        backgroundSessionCompletionHandler?()
        backgroundSessionCompletionHandler = nil
    }
}
