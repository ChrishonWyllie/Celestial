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
    
    public func videoExists(for sourceURL: URL, cacheLocation: ResourceCacheLocation) -> Bool {
        return cachedResourceAndIdentifierExists(for: sourceURL, resourceType: .video, cacheLocation: cacheLocation)
    }
   
    public func videoFromMemoryCache(sourceURLString: String) -> MemoryCachedVideoData? {
        return VideoCache.shared.item(for: sourceURLString.convertURLToUniqueFileName())
    }
   
    public func videoURLFromFileCache(sourceURL: URL) -> URL? {
        return FileStorageManager.shared.getCachedVideoURL(for: sourceURL)
    }

    public func storeVideoInMemoryCache(videoData: MemoryCachedVideoData?, sourceURLString: String) {
        guard let sourceURL = URL(string: sourceURLString) else {
            fatalError("\(sourceURLString) is not a valid URL")
        }
        let resourceIdentifier = CachedResourceIdentifier(sourceURL: sourceURL,
                                                          resourceType: .video,
                                                          cacheLocation: .inMemory)
        storeReferenceTo(cachedResource: resourceIdentifier)
        VideoCache.shared.store(videoData, with: sourceURLString.convertURLToUniqueFileName())
    }
   
    public func storeDownloadedVideoToFileCache(_ temporaryFileURL: URL, withSourceURL sourceURL: URL, completion: @escaping (URL?) -> ()) {
        FileStorageManager.shared.cachedAndResizedVideo(sourceURL: sourceURL, intermediateTemporaryFileURL: temporaryFileURL, completion: { [weak self] (cachedVideoURL) in
            
            let resourceIdentifier = CachedResourceIdentifier(sourceURL: sourceURL,
                                                              resourceType: .video,
                                                              cacheLocation: .fileSystem)
            self?.storeReferenceTo(cachedResource: resourceIdentifier)
            
            completion(cachedVideoURL)
        })
    }
    
    public func removeVideoFromMemoryCache(sourceURLString: String) {
        VideoCache.shared.removeItem(at: sourceURLString.convertURLToUniqueFileName())
        removeResourceIdentifier(for: sourceURLString)
    }
   
    public func removeVideoFromFileCache(sourceURLString: String) -> Bool {
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
    
    public func imageExists(for sourceURL: URL, cacheLocation: ResourceCacheLocation) -> Bool {
        return cachedResourceAndIdentifierExists(for: sourceURL, resourceType: .image, cacheLocation: cacheLocation)
    }
    
    public func imageFromMemoryCache(sourceURLString: String) -> UIImage? {
       return ImageCache.shared.item(for: sourceURLString.convertURLToUniqueFileName())
    }
    
    public func imageURLFromFileCache(sourceURL: URL, pointSize: CGSize) -> URL? {
        return FileStorageManager.shared.getCachedImageURL(for: sourceURL, size: pointSize)
    }
    
    public func storeImageInMemoryCache(image: UIImage?, sourceURLString: String) {
        guard let sourceURL = URL(string: sourceURLString) else {
            fatalError("\(sourceURLString) is not a valid URL")
        }
        let resourceIdentifier = CachedResourceIdentifier(sourceURL: sourceURL,
                                                          resourceType: .image,
                                                          cacheLocation: .inMemory)
        storeReferenceTo(cachedResource: resourceIdentifier)
        ImageCache.shared.store(image, with: sourceURLString.convertURLToUniqueFileName())
    }
    
    public func storeDownloadedImageToFileCache(_ temporaryFileURL: URL, withSourceURL sourceURL: URL, pointSize: CGSize, completion: @escaping (UIImage?) -> ()) {
        
        FileStorageManager.shared.cachedAndResizedImage(sourceURL: sourceURL, size: pointSize, intermediateTemporaryFileURL: temporaryFileURL, completion: { [weak self] (cachedImageURL) in
            
            let resourceIdentifier = CachedResourceIdentifier(sourceURL: sourceURL, resourceType: .image, cacheLocation: .fileSystem)
            self?.storeReferenceTo(cachedResource: resourceIdentifier)
            
            completion(cachedImageURL)
        })
    }
    
    public func removeImageFromMemoryCache(sourceURLString: String) {
        ImageCache.shared.removeItem(at: sourceURLString)
        removeResourceIdentifier(for: sourceURLString)
    }
    
    public func removeImageFromFileCache(sourceURLString: String) -> Bool {
        
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
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.handleScrollViewPrefetching(forRequestedItems: urlStrings) { (url, resourceExistenceState) in
                
                switch resourceExistenceState {
                case .none:
                    strongSelf.startDownload(for: url)
                case .downloadPaused:
                    strongSelf.resumeDownload(for: url)
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
            
            strongSelf.handleScrollViewPrefetching(forRequestedItems: urlStrings) { (url, resourceExistenceState) in
                
                switch resourceExistenceState {
                case .none, .downloadPaused, .cached, .uncached:
                    // Nothing more to do
                    break
                case .currentlyDownloading:
                    if cancelCompletely {
                        strongSelf.cancelDownload(for: url)
                    } else {
                        strongSelf.pauseDownload(for: url)
                    }
                }
            }
        }
    }
    
    private func handleScrollViewPrefetching(forRequestedItems urlStrings: [String], performSomeOpertionUsingURL: @escaping (URL, ResourceExistenceState) -> ()) {
        for sourceURLString in urlStrings {
        
            guard let sourceURL = URL(string: sourceURLString) else {
                fatalError("\(sourceURLString) is not a valid URL")
            }
            
            let resourceExistenceState = determineResourceExistenceState(forSourceURL: sourceURL,
                                                                         ifCacheLocationIsKnown: nil,
                                                                         ifResourceTypeIsKnown: nil)
            
            performSomeOpertionUsingURL(sourceURL, resourceExistenceState)
        }
    }
}







// MARK: - MemoryCache

extension Celestial: CelestialMemoryCacheProtocol {
    
    func setMemoryCacheItemLimits(videoCache: Int? = nil, imageCache: Int? = nil) {
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
        DownloadTaskManager.shared.cancelAllDownloads()
        clearAllResourceIdentifiers()
        clearAllImages()
        clearAllVideos()
    }
    
    public func getCacheInfo() -> [String] {
        return FileStorageManager.shared.getCacheInfo().map { "\n\($0)" }
    }
    
    
    
    
    
    
    internal func exchangeDownloadModel(newDownloadModel: GenericDownloadModel) {
        DownloadTaskManager.shared.exchangeDownloadModel(newModel: newDownloadModel)
    }
    
    internal func resumeDownload(downloadModel: GenericDownloadModel) {
        DownloadTaskManager.shared.resumeDownload(model: downloadModel)
    }
    
    internal func startDownload(downloadModel: GenericDownloadModel) {
        DownloadTaskManager.shared.startDownload(model: downloadModel)
    }
    
    internal func deleteFile(at location: URL, deleteReferenceForSourceURL url: URL? = nil) {
        if let sourceURL = url {
            removeResourceIdentifier(for: sourceURL.absoluteString)
        }
        DispatchQueue.global(qos: .background).async {
            FileStorageManager.shared.deleteFile(at: location)
        }
    }
    
    internal func getTemporarilyCachedFileURL(for sourceURL: URL) -> URL? {
        return FileStorageManager.shared.getTemporarilyCachedFileURL(for: sourceURL)
    }
    
    internal func decreaseVideoQuality(sourceURL: URL, inputURL: URL, completion: @escaping (_ lowerQualityVideoURL: URL?) -> ()) {
        FileStorageManager.shared.decreaseVideoQuality(sourceURL: sourceURL, inputURL: inputURL, completion: completion)
    }
}

















// MARK: - CachedResourceIdentifier

extension Celestial {
    
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
    
    private func loadCachedResourceIdentifiers() {
        
        guard
            let cachedResourcesData = UserDefaults.standard.value(forKey: resourceIdentifiersKey) as? Data,
            let locallyStoredCachedResourceReferences = try? PropertyListDecoder().decode(Array<CachedResourceIdentifier>.self, from: cachedResourcesData) else {
                
            threadUnsafeCachedResourceIdentifiers = []
            return
        }
        threadUnsafeCachedResourceIdentifiers = locallyStoredCachedResourceReferences
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
                                         ifCacheLocationIsKnown cacheLocation: ResourceCacheLocation?,
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
    
    private func cachedResourceAndIdentifierExists(for sourceURL: URL, resourceType: ResourceFileType, cacheLocation: ResourceCacheLocation) -> Bool {
        var identifierExists = resourceIdentifierExists(for: sourceURL)
        var fileExists: Bool = false
        
        switch cacheLocation {
        case .inMemory:
            if resourceType == .video {
                fileExists = videoFromMemoryCache(sourceURLString: sourceURL.absoluteString) != nil
            } else {
                fileExists = imageFromMemoryCache(sourceURLString: sourceURL.absoluteString) != nil
            }
        case .fileSystem:
            if resourceType == .video {
                fileExists = FileStorageManager.shared.videoExists(for: sourceURL)
            } else {
                fileExists = FileStorageManager.shared.imageExists(for: sourceURL)
            }
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
