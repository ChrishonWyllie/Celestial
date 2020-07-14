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
    
    internal var cachedResourceIdentifiers: [CachedResourceIdentifier] {
        var identifiers: [CachedResourceIdentifier]!
        
        concurrentQueue.sync { [weak self] in
            guard let strongSelf = self else { return }
            identifiers = strongSelf.threadUnsafeCachedResourceIdentifiers
        }
        return identifiers
    }
    
    private var threadUnsafeCachedResourceIdentifiers: [CachedResourceIdentifier] = []
    
    private let concurrentQueue = DispatchQueue(label: "com.chrishonwyllie.Celestial.CachedResourceIdentifiers.concurrentQueue", attributes: .concurrent)
    
    private let resourceIdentifiersKey = "com.chrishonwyllie.Celestial.CachedResourceIdentifiers.UserDefaults.key"
    
    
    
    
    
    // MARK: - Initializers
    
    private override init() {
        super.init()
        loadCachedResourceIdentifiers()
    }
}






// MARK: - Video

extension Celestial: CelestialVideoCachingProtocol {
    
    public func videoExists(for sourceURL: URL, cacheLocation: DownloadCompletionCacheLocation) -> Bool {
        return cachedResourceAndIdentifierExists(for: sourceURL, resourceType: .video, cacheLocation: cacheLocation)
    }
   
    public func videoData(for sourceURLString: String) -> MemoryCachedVideoData? {
        return VideoCache.shared.item(for: sourceURLString.convertURLToUniqueFileName())
    }
   
    public func videoURL(for sourceURL: URL) -> URL? {
        return FileStorageManager.shared.getCachedVideoURL(for: sourceURL)
    }

    public func store(videoData: MemoryCachedVideoData?, with sourceURLString: String) {
        guard let sourceURL = URL(string: sourceURLString) else {
            fatalError("\(sourceURLString) is not a valid URL")
        }
        let resourceIdentifier = CachedResourceIdentifier(sourceURL: sourceURL,
                                                          resourceType: .video,
                                                          cacheLocation: .inMemory)
        storeReferenceTo(cachedResource: resourceIdentifier)
        VideoCache.shared.store(videoData, with: sourceURLString.convertURLToUniqueFileName())
    }
   
    public func storeVideoURL(_ temporaryFileURL: URL, withSourceURL sourceURL: URL, completion: @escaping (URL?) -> ()) {
        
        FileStorageManager.shared.cachedAndResizedVideo(sourceURL: sourceURL, intermediateTemporaryFileURL: temporaryFileURL, completion: { [weak self] (cachedVideoURL) in
            
            let resourceIdentifier = CachedResourceIdentifier(sourceURL: sourceURL,
                                                              resourceType: .video,
                                                              cacheLocation: .fileSystem)
            self?.storeReferenceTo(cachedResource: resourceIdentifier)
            
            completion(cachedVideoURL)
        })
    }
   
    public func removeVideoData(using sourceURLString: String) {
        VideoCache.shared.removeItem(at: sourceURLString.convertURLToUniqueFileName())
        removeResourceIdentifier(for: sourceURLString)
    }
   
    public func removeVideoURL(using sourceURLString: String) -> Bool {
        guard let sourceURL = URL(string: sourceURLString) else {
            fatalError("\(sourceURLString) is not a valid URL")
        }
        let successfullyDeletedResource = FileStorageManager.shared.deleteCachedVideo(using: sourceURL)
        if successfullyDeletedResource {
            removeResourceIdentifier(for: sourceURLString)
        }
        return successfullyDeletedResource
    }
   
    public func clearAllVideos() {
        clearResourceIdentifiers(withResourceType: .video)
        VideoCache.shared.clearAllItems()
        FileStorageManager.shared.clearCache(fileType: ResourceFileType.video)
    }
}



// MARK: - Image

extension Celestial: CelestialImageCachingProtocol {
    
    public func imageExists(for sourceURL: URL, cacheLocation: DownloadCompletionCacheLocation) -> Bool {
        return cachedResourceAndIdentifierExists(for: sourceURL, resourceType: .image, cacheLocation: cacheLocation)
    }
    
    public func image(for sourceURLString: String) -> UIImage? {
        return ImageCache.shared.item(for: sourceURLString.convertURLToUniqueFileName())
    }
    
    public func imageURL(for sourceURL: URL, pointSize: CGSize) -> URL? {
        return FileStorageManager.shared.getCachedImageURL(for: sourceURL, size: pointSize)
    }
    
    public func store(image: UIImage?, with sourceURLString: String) {
        guard let sourceURL = URL(string: sourceURLString) else {
            fatalError("\(sourceURLString) is not a valid URL")
        }
        let resourceIdentifier = CachedResourceIdentifier(sourceURL: sourceURL,
                                                          resourceType: .image,
                                                          cacheLocation: .inMemory)
        storeReferenceTo(cachedResource: resourceIdentifier)
        ImageCache.shared.store(image, with: sourceURLString.convertURLToUniqueFileName())
    }
    
    public func storeImageURL(_ temporaryFileURL: URL, withSourceURL sourceURL: URL, pointSize: CGSize, completion: @escaping (_ resizedImage: UIImage?) -> ()) {
        
        FileStorageManager.shared.cachedAndResizedImage(sourceURL: sourceURL, size: pointSize, intermediateTemporaryFileURL: temporaryFileURL, completion: { [weak self] (cachedImageURL) in
            
            let resourceIdentifier = CachedResourceIdentifier(sourceURL: sourceURL, resourceType: .image, cacheLocation: .fileSystem)
            self?.storeReferenceTo(cachedResource: resourceIdentifier)
            
            completion(cachedImageURL)
        })
    }
    public func removeImage(using sourceURLString: String) {
        ImageCache.shared.removeItem(at: sourceURLString)
        removeResourceIdentifier(for: sourceURLString)
    }
    
    public func removeImageURL(using sourceURLString: String) -> Bool {
        guard let sourceURL = URL(string: sourceURLString) else {
            fatalError("\(sourceURLString) is not a valid URL")
        }
        let successfullyDeletedResource = FileStorageManager.shared.deleteCachedImage(using: sourceURL)
        if successfullyDeletedResource {
            removeResourceIdentifier(for: sourceURLString)
        }
        return successfullyDeletedResource
    }
    
    public func clearAllImages() {
        clearResourceIdentifiers(withResourceType: .image)
        ImageCache.shared.clearAllItems()
        FileStorageManager.shared.clearCache(fileType: ResourceFileType.image)
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
    
    public func prefetchResources(at urlStrings: [String]) {
        
        handleScrollViewPrefetching(forRequestedItems: urlStrings) { [weak self] (url, downloadState) in
            guard let strongSelf = self else { return }
            switch downloadState {
            case .none:
                strongSelf.startDownload(for: url)
            case .paused:
                strongSelf.resumeDownload(for: url)
            case .downloading, .finished:
                // Nothing more to do
                break
            }
        }
    }
    
    public func pausePrefetchingForResources(at urlStrings: [String], cancelCompletely: Bool) {
        
        handleScrollViewPrefetching(forRequestedItems: urlStrings) { [weak self] (url, downloadState) in
            guard let strongSelf = self else { return }
            switch downloadState {
            case .none, .finished, .paused:
                // Nothing more to do
                break
            case .downloading:
                if cancelCompletely {
                    strongSelf.cancelDownload(for: url)
                } else {
                    strongSelf.pauseDownload(for: url)
                }
            }
        }
    }
    
    private func handleScrollViewPrefetching(forRequestedItems urlStrings: [String], performOperationOnURL: @escaping (URL, DownloadTaskState) -> ()) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let strongSelf = self else { return }
            for urlString in urlStrings {
            
                guard let url = URL(string: urlString) else {
                    fatalError("\(urlString) is not a valid URL")
                }
                
                let downloadState = strongSelf.downloadState(for: url)
                
                performOperationOnURL(url, downloadState)
            }
        }
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
        default:
            if imageExists(for: sourceURL, cacheLocation: .fileSystem) && cacheLocation == .inMemory ||
                imageExists(for: sourceURL, cacheLocation: .inMemory) && cacheLocation == .fileSystem
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
        clearAllResourceIdentifiers()
        clearAllImages()
        clearAllVideos()
    }
    
    public func getCacheInfo() -> [String] {
        return FileStorageManager.shared.getCacheInfo().map { "\n\($0)" }
    }
    
}

















// MARK: - CachedResourceIdentifier

extension Celestial {
    
    private func loadCachedResourceIdentifiers() {
        
        guard
            let cachedResourcesData = UserDefaults.standard.value(forKey: resourceIdentifiersKey) as? Data,
            let locallyStoredCachedResourceReferences = try? PropertyListDecoder().decode(Array<CachedResourceIdentifier>.self, from: cachedResourcesData) else {
                
            threadUnsafeCachedResourceIdentifiers = []
            return
        }
        threadUnsafeCachedResourceIdentifiers = locallyStoredCachedResourceReferences
    }
    
    internal func storeReferenceTo(cachedResource: CachedResourceIdentifier) {
        
        guard threadUnsafeCachedResourceIdentifiers.contains(cachedResource) == false else {
            return
        }
        
        threadUnsafeCachedResourceIdentifiers.append(cachedResource)
        
        do {
            let encodedData = try PropertyListEncoder().encode(threadUnsafeCachedResourceIdentifiers)
            UserDefaults.standard.set(encodedData, forKey: resourceIdentifiersKey)
        } catch let error {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error encoding resource identifiers array to data. Error: \(error)")
        }
    }
    
    internal func removeResourceIdentifier(for sourceURLString: String) {
        guard let sourceURL = URL(string: sourceURLString) else {
            fatalError("\(sourceURLString) is not a valid URL")
        }
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let strongSelf = self else { return }
            guard
                strongSelf.cachedResourceIdentifiers.count > 0,
                let arrayElementIndex = strongSelf.cachedResourceIdentifiers.firstIndex(where: { $0.sourceURL == sourceURL }) else {
                return
            }
            strongSelf.threadUnsafeCachedResourceIdentifiers.remove(at: Int(arrayElementIndex))
            strongSelf.saveResourceIdentifiersInUserDefaults()
        }
    }
    
    internal func clearAllResourceIdentifiers() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.threadUnsafeCachedResourceIdentifiers.count > 0 else {
                return
            }
            strongSelf.threadUnsafeCachedResourceIdentifiers.removeAll(keepingCapacity: false)
            strongSelf.saveResourceIdentifiersInUserDefaults()
        }
    }
    
    internal func clearResourceIdentifiers(withResourceType resourceType: ResourceFileType) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.threadUnsafeCachedResourceIdentifiers.count > 0 else {
                return
            }
            strongSelf.threadUnsafeCachedResourceIdentifiers.removeAll(where: { $0.resourceType == resourceType })
            strongSelf.saveResourceIdentifiersInUserDefaults()
        }
    }
    
    private func saveResourceIdentifiersInUserDefaults() {
        do {
            let encodedData = try PropertyListEncoder().encode(threadUnsafeCachedResourceIdentifiers)
            UserDefaults.standard.set(encodedData, forKey: resourceIdentifiersKey)
        } catch let error {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error encoding resource identifiers array to data. Error: \(error)")
        }
    }
    
    internal func resourceIdentifier(for sourceURL: URL) -> CachedResourceIdentifier? {
        let cachedResourceReferencesMatchingURL = cachedResourceIdentifiers.filter({ $0.sourceURL == sourceURL })
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Checking for CachedResourceIdentifier matching url: \(sourceURL). Resource identifiers: \(cachedResourceIdentifiers)")
        
        if cachedResourceReferencesMatchingURL.count > 1 {
            fatalError("Internal inconsistency. There can only be 0 (non-existent) or 1 identifier for a single URL: \(sourceURL)")
        }
        
        return cachedResourceReferencesMatchingURL.first
    }
    
    internal func resourceIdentifierExists(for sourceURL: URL) -> Bool {
        
        var resourceExists: Bool = false
        
        if let resourceIdentifier = resourceIdentifier(for: sourceURL) {
            
            resourceExists = true
            
            switch resourceIdentifier.cacheLocation {
            case .inMemory:
                break
            case .fileSystem:
                if let info = FileStorageManager.shared.getInfoForStoredResource(matchingSourceURL: resourceIdentifier.sourceURL,
                                                                                 fileType: resourceIdentifier.resourceType) {
                
                    if info.fileSize == 0 {
                        // Upon further inspection,
                        // the file does not actually exist.
                        // There is no data at the specified file URL.
                        // An error may have occured, such as moving app to background
                        // during some process that cannot continue unless app
                        // is in foreground
                        // Such as AVAssextExportSession for videos
                        
                        try? FileManager.default.removeItem(at: info.fileURL)
                        
                        resourceExists = false
                    }
                } else {
                    resourceExists = false
                }
            }
        }
        
        return resourceExists
    }
    
    func determineResourceExistenceState(forSourceURL sourceURL: URL,
                                         ifCacheLocationIsKnown cacheLocation: DownloadCompletionCacheLocation?,
                                         ifResourceTypeIsKnown resourceType: ResourceFileType?) -> ResourceExistenceState {
        
        if let cacheLocation = cacheLocation, let resourceType = resourceType {
            if cachedResourceAndIdentifierExists(for: sourceURL, resourceType: resourceType, cacheLocation: cacheLocation) {
                return .cached
            } else {
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
                if imageExists(for: sourceURL, cacheLocation: .fileSystem) && cacheLocation == .inMemory ||
                    imageExists(for: sourceURL, cacheLocation: .inMemory) && cacheLocation == .fileSystem
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
    
    private func cachedResourceAndIdentifierExists(for sourceURL: URL, resourceType: ResourceFileType, cacheLocation: DownloadCompletionCacheLocation) -> Bool {
        var identifierExists = resourceIdentifierExists(for: sourceURL)
        var fileExists: Bool = false
        
        switch cacheLocation {
        case .inMemory:
            fileExists = videoData(for: sourceURL.localUniqueFileName) != nil
        case .fileSystem:
            fileExists = FileStorageManager.shared.videoExists(for: sourceURL)
        }
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - source url: \(sourceURL). local unique identifier: \(sourceURL.localUniqueFileName)")
        
        if identifierExists != fileExists {
            let resourceIdentifier = CachedResourceIdentifier(sourceURL: sourceURL, resourceType: resourceType, cacheLocation: cacheLocation)
            storeReferenceTo(cachedResource: resourceIdentifier)
            identifierExists = true
        }
        
        return identifierExists && fileExists
    }
}
