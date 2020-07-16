//
//  MultimediaCacheProtocols.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import UIKit.UIImage

// MARK: - CelestialVideoCachingProtocol

/// Forces conformance for implementing functions related to video caching
internal protocol CelestialVideoCachingProtocol: class {
    
    /**
     Returns a boolean value of whether a video exists

    - Parameters:
       - sourceURL: The original external URL pointing to the media resource on the server, etc.
       - cacheLocation: Determines where to look for the cached item if it exists
     
    - Returns:
       - A boolean value of whether the requested resource has been previously cached
    */
    func videoExists(for sourceURL: URL, cacheLocation: ResourceCacheLocation) -> Bool
    
    
    
    
    
    
    /**
     Returns struct for video data from in-memory cache

    - Parameters:
       - sourceURLString: The original external URL pointing to the media resource on the server, etc.
     
    - Usage:
    ```
    let urlString = <external URL pointing to your media>
     
    guard let originalVideoData = Celestial.shared.videoFromMemoryCache(sourceURLString: urlString) else {
        return
    }
    ```
     
    - Returns: A `MemoryCachedVideoData` object which contains the data of the video file, the mime type and file extension of the original source URL.
    */
    func videoFromMemoryCache(sourceURLString: String) -> MemoryCachedVideoData?
    
    
    
    
    
    
    
    /**
     Returns a file URL pointing to the video cached in file system using the source url as the key.

    - Parameters:
       - sourceURL: The original external URL pointing to the media resource on the server, etc.
     
    - Usage:
    ```
    let sourceURL = <external URL pointing to your media>
     
    guard let videoFileURL = Celestial.shared.videoURLFromFileCache(sourceURL: sourceURL) else {
        return
    }
    ```
     
    - Returns: A URL pointing to the video in file system.
    */
    func videoURLFromFileCache(sourceURL: URL) -> URL?
    
    
    
    
    
    
    
    /**
     Caches the specified video data, its mime type and file extension using the `MemoryCachedVideoData` struct to in-memory cache

    - Parameters:
       - videoData: The `MemoryCachedVideoData` object which contains the Data of the video, the mime type and file extension of the original URL . This is necessary for rebuilding the video after caching.
       - sourceURLString: The original external URL pointing to the media resource on the server, etc.
     
    - Usage:
    ```
    let urlString = <external URL pointing to your media>
     
    let originalVideoData = MemoryCachedVideoData(videoData: <your value>, mimeType: url.mimeType(), fileExtension: url.pathExtension)
     
    Celestial.shared.storeVideoInMemoryCache(videoData: originalVideoData, sourceURLString: urlString)
    ```
     
    */
    func storeVideoInMemoryCache(videoData: MemoryCachedVideoData?, sourceURLString: String)
    
    
    
    
    
    /**
     Caches the downloaded video to file system cache using its file URL.
     Use this function when moving the downloaded video from its temporary file system location to a more permanent location.
     
    - Parameters:
       - temporaryFileURL: The temporary URL of the image after the `URLSessionDownloadTask` has completed.
       - sourceURL: The original external URL pointing to the media resource on the server, etc.
       - completion: Executes completion block with a URL pointing to a compressed video
     
    - Usage:
    ```
    let downloadVideoURL = <local file URL from URLSessionDownloadTask pointing to your downloaded media>
    let sourceURL = <external URL pointing to your media>
     
    Celestial.shared.storeDownloadedVideoToFileCache(downloadVideoURL, with: sourceURL) { (cachedVideoFileURL) in
        // Unwrap optional file URL...
    }
    ```
     
    */
    func storeDownloadedVideoToFileCache(_ temporaryFileURL: URL, withSourceURL sourceURL: URL, completion: @escaping (URL?) -> ())
    
    
    
    
    /**
     Evicts the video from the in-memory cache
     
    - Warning: This is irreversible. The cache will no longer contain a value for this key, thus requiring the video to be redownloaded and re-cached.
     
    - Parameters:
       - sourceURLString: The original external URL pointing to the media resource on the server, etc.
     
    - Usage:
    ```
    let urlString = <external URL pointing to your media>
     
    Celestial.shared.removeVideoFromMemoryCache(ussourceURLStringing: urlString)
    ```
     
    */
    func removeVideoFromMemoryCache(sourceURLString: String)
    
    
    
    
    
    
    
    
    /**
     Evicts the video from the file system cache
     
    - Warning: This is irreversible. The cache will no longer contain a value for this key, thus requiring the video to be redownloaded and re-cached.
     
    - Parameters:
       - sourceURLString: The original external URL pointing to the media resource on the server, etc.
     
    - Usage:
    ```
    let urlString = <external URL pointing to your media>
     
    Celestial.shared.removeVideoFromFileCache(sourceURLString: urlString)
    ```
     
    - Returns:
        A Boolean value of whether the video represented by the sourceURL has been deleted
    */
    func removeVideoFromFileCache(sourceURLString: String) -> Bool
    
    
    
    
    /**
     Evicts all items from the Video cache. Both in memory and in file system
     
    - Warning: This is irreversible. The video cache will be completely empty: all videos thereafter will need to be redownloaded and re-cached.
    
    - Usage:
    ```
    Celestial.shared.clearAllVideos()
    ```
     
    */
    func clearAllVideos()
}



// MARK: - CelestialImageCachingProtocol

/// Forces conformance for implementing functions related to image caching
internal protocol CelestialImageCachingProtocol: class {
    
    /**
     Returns a boolean value of whether an image exists

    - Parameters:
       - sourceURL: The original external URL pointing to the media resource on the server, etc.
       - cacheLocation: Determines where to look for the cached item if it exists
     
    - Returns:
       - A boolean value of whether the requested resource has been previously cached
    */
    func imageExists(for sourceURL: URL, cacheLocation: ResourceCacheLocation) -> Bool
    
    
    
    
    
    
    /**
     Returns a image cached in memory using the source url as the key

    - Parameters:
       - sourceURLString: The original external URL pointing to the media resource on the server, etc.
    
    - Usage:
    ```
    let urlString = <external URL pointing to your media>
     
    guard let image = Celestial.shared.imageFromMemoryCache(for: urlString) else {
        return
    }
    ```
     
    - Returns:
       - A `UIImage` at the specified source URL
    */
    func imageFromMemoryCache(sourceURLString: String) -> UIImage?
    
    
    
    
    
    
    
    
    
    
    
    /**
     Returns a file URL pointing to the image cached in file system using the source url as the key.
     Also takes pointSize argument for allowing images to be cached for multiple iOS point sizes

    - Parameters:
       - sourceURLString: The original external URL pointing to the media resource on the server, etc.
       - pointSize: The CGrect.CGSize of the image that will be displated
    
    - Usage:
    ```
    let sourceURL = <external URL pointing to your media>
    let pointSize: CGSize = <CGSize of your URLImageView, etc.>
     
    guard let image = Celestial.shared.imageURLFromFileCache(sourceURL: sourceURL, pointSize: pointSize) else {
        return
    }
    ```
     
    - Returns:
       - A URL pointing to the image cached image in file system that is the same point size as the one requested
    */
    func imageURLFromFileCache(sourceURL: URL, pointSize: CGSize) -> URL?
    
    
    
    
    
    
    
    
    /**
     Caches the UIImage to in-memory cache

    - Parameters:
       - image: The `UIImage` to be cached in memory
       - sourceURLString: The original external URL pointing to the media resource on the server, etc.
    
    - Usage:
    ```
    let downloadImage = <some UIImage>
    let urlString = <external URL pointing to your media>
     
    Celestial.shared.storeImageInMemoryCache(image: downloadedImage, sourceURLString: urlString)
    ```
     
    */
    func storeImageInMemoryCache(image: UIImage?, sourceURLString: String)
    
    
    
    
    
    
    
    
    
    
    
    /**
     Caches the downloaded image to file system cache using its file URL.
     Use this function when moving the downloaded image from its temporary file system location to a more permanent location.
     

    - Parameters:
       - temporaryFileURL: The temporary/local file URL pointing to the image after the `URLSessionDownloadTask` has completed.
       - sourceURL: The original external URL pointing to the resource on the server, etc.
       - pointSize: The iOS point size of the image. Will be used to store and retrieve the same image at different sizes
    
    - Usage:
    ```
    let downloadImageURL = <local file URL from URLSessionDownloadTask pointing to your downloaded media>
    let sourceURL = <external URL pointing to your media>
    let pointSize = <Your desired point size, possibly after layout finishes>
     
    Celestial.shared.storeDownloadedImageToFileCache(downloadedImageURL, with: sourceURL, pointSize: pointSize) { (cachedImageFileURL) in
        // Unwrap optional file URL...
    }
    ```
     
    - Returns:
        A `UIImage` that has been resized to the desired iOS point size
    */
    func storeDownloadedImageToFileCache(_ temporaryFileURL: URL, withSourceURL sourceURL: URL, pointSize: CGSize, completion: @escaping (_ resizedImage: UIImage?) -> ())
    
    
    
    
    
    
    
    
    /**
     Evicts the image at the specified url string from the in-memory cache.

    - Warning: This is irreversible. The in-memory cache will no longer contain a value for this key, thus requiring the image to be redownloaded and re-cached.
     
    - Parameters:
       - sourceURLString: The original external URL pointing to the media resource on the server, etc.
    
    - Usage:
    ```
    let urlString = <external URL pointing to your media>
     
    Celestial.shared.removeImageFromMemoryCache(sourceURLString: urlString)
    ```
     
    */
    func removeImageFromMemoryCache(sourceURLString: String)
    
    
    
    
    
    
    
    /**
     Evicts the image from the file system cache

    - Warning: This is irreversible. The cache will no longer contain a value for this key, thus requiring the image to be redownloaded and re-cached.
     
    - Parameters:
       - sourceURLString: The original external URL pointing to the media resource on the server, etc.
    
    - Usage:
    ```
    let urlString = <external URL pointing to your media>
     
    Celestial.shared.removeImageFromFileCache(sourceURLString: urlString)
    ```
     
    - Returns:
        A Boolean value of whether the image represented by the sourceURL has successfully been deleted from the file system
    */
    func removeImageFromFileCache(sourceURLString: String) -> Bool
    
    
    
    
    
    
    /**
     Evicts all items from the Image cache. Both in-memory and in-filesystem
     
    - Warning: This is irreversible. The image cache will be completely empty: all images thereafter will need to be redownloaded and re-cached.
    
    - Usage:
    ```
    Celestial.shared.clearAllImages()
    ```
    */
    func clearAllImages()
}



// MARK: - CelestialResourcePrefetchingProtocol

/// Forces conformance for implementing functions related to manually managing the state of resource
/// prior to the URLCachableView being available. 
internal protocol CelestialResourcePrefetchingProtocol: class {
    
    /**
     Provides the current download state of a requested resource
     
    - Parameters:
        - sourceURL: The original external URL pointing to the media resource on the server, etc.
       
    - Usage:
    ```
    let urlString = <external URL pointing to your media>
    guard let url = URL(string: urlString) else {
        return
    }
     
    let downloadState = Celestial.shared.downloadState(for: url)
 
    switch downloadState {
    case .downloading: ...
    }
    ```
     
    - Returns:
        An enum case representing the current download state of a requested resource
    */
    func downloadState(for sourceURL: URL) -> DownloadTaskState
    
    /**
     Begins loading the requested resource using its URL
     
    - Parameters:
        - sourceURL: The original external URL pointing to the media resource on the server, etc.
       
    - Usage:
    ```
    let urlString = <external URL pointing to your media>
    guard let url = URL(string: urlString) else {
        return
    }
     
    Celestial.shared.startDownload(for: url)
    ```
     
    */
    func startDownload(for sourceURL: URL)
    
    /**
     Pauses the current download of the requested resource if a download was previously initiated
     
    - Parameters:
        - sourceURL: The original external URL pointing to the media resource on the server, etc.
       
    - Usage:
    ```
    let urlString = <external URL pointing to your media>
    guard let url = URL(string: urlString) else {
        return
    }
     
    Celestial.shared.pauseDownload(for: url)
    ```
     
    */
    func pauseDownload(for sourceURL: URL)
    
    /**
     Resumes download of the requested resource if a download was previously initiated and paused
     
    - Parameters:
        - sourceURL: The original external URL pointing to the media resource on the server, etc.
       
    - Usage:
    ```
    let urlString = <external URL pointing to your media>
    guard let url = URL(string: urlString) else {
        return
    }
     
    Celestial.shared.resumeDownload(for: url)
    ```
     
    */
    func resumeDownload(for sourceURL: URL)
    
    /**
     Cancels a current download for a requested resource if a download was previously initated
       
    - Parameters:
        - sourceURL: The original external URL pointing to the media resource on the server, etc.
     
    - Usage:
    ```
    let urlString = <external URL pointing to your media>
    guard let url = URL(string: urlString) else {
        return
    }
     
    Celestial.shared.cancelDownload(for: url)
    ```
     
    */
    func cancelDownload(for sourceURL: URL)
    
    /**
     Begins download on multiple requested resources. Intended for use in UICollectionView/UITableView prefetch delegate functions
       
    - Parameters:
        - urlStrings: The external URLs pointing to the media resources on the server, etc.
     
    - Usage:
    ```
    let urlStrings: [String] = [<array of your URLs>]
     
    Celestial.shared.prefetchResources(at: urlStrings)
    ```
     
    */
    func prefetchResources(at urlStrings: [String])
    
    /**
     Pauses (and cancels if desired) downloads on multiple requested resources. Intended for use in UICollectionView/UITableView prefetch delegate functions
       
    - Parameters:
        - urlStrings: The external URLs pointing to the media resources on the server, etc.
        - cancelCompletely: Completely cancels the download instead of just temporarily pausing
     
    - Usage:
    ```
    let urlStrings: [String] = [<array of your URLs>]
     
    Celestial.shared.pausePrefetchingForResources(at: urlStrings, cancelCompletely: ?)
    ```
     
    */
    func pausePrefetchingForResources(at urlStrings: [String], cancelCompletely: Bool)
    
}


// MARK: - CelestialMemoryCacheProtocol

/// Forces conformance for implementing functions related to in-memory caching
internal protocol CelestialMemoryCacheProtocol: class {
    
    /**
     Sets the maximum number of items that can be stored in either the video or image cache.
     e.g., specifying `100` for videoCache means at max, 100 videos may be stored.
     However, according to the Apple documentation, this is not a strict limit.
     Passing in nil for either argument will leave its respective cache unaffected and use the previous value
     or default value.
     
    - Parameters:
       - videoCache: Integer value representing the number of items the Video cache should be limited to.
       - imageCache: Integer value representing the number of items the Image cache should be limited to.
    
    - Usage:
    ```
    Celestial.shared.setMemoryCacheItemLimits(videoCache: 100, imageCache: 100)
    ```
     
    */
    func setMemoryCacheItemLimits(videoCache: Int?, imageCache: Int?)
    
    
    
    
    
    /**
     Sets the maximum cost of items that can be stored in either the video or image cache.
     NOTE: This value is in number of bytes. Use `Int.OneMegabyte (1024 * 1024) * <your value>` or `Int.OneGigabyte (1024 * 1024 * 1000) * <your value>`
     This means that with each additional item stored in the cache, the available space will decrease by the size of the item.
     e.g., if the cost limit is set to 100 MB (104857600 bytes)
     However, according to the Apple documentation, this is not a strict limit.
     Passing in nil for either argument will leave its respective cache unaffected and use the previous value
     or default value.
     
    - Parameters:
       - videoCache: Integer value representing the number of bytes the Video cache should be limited to.
       - imageCache: Integer value representing the number of bytes the Image cache should be limited to.
     
    - Usage:
    ```
    Celestial.shared.setMemoryCacheCostLimits(videoCache: Int.OneGigabyte, imageCache: Int.OneMegabyte * 100)
    ```
     
    */
    func setMemoryCacheCostLimits(videoCache: Int?, imageCache: Int?)
    
}



// MARK: - CelestialMiscellaneousProtocol

/// Forces conformance for implementing miscellaneous utility functions that otherwise do not fit in the other protocols,
/// but are necessary nonetheless
internal protocol CelestialUtilityProtocol: class {
    /**
     Sets an internal Boolean value which determines whether debug statements will be printed to console.
     For example, information regarding when the image or video cache is evicting items for memory space
     will be printed.
     It is set to `false` by default
    
    - Parameters:
        - on: Boolean value which will determine if debug statements will be printed to console.
     
    - Usage:
    ```
    Celestial.shared.setDebugMode(on: true)
    ```
     
    */
    func setDebugMode(on: Bool)
    
    /**
     Evicts all items from both the video and image caches.
    
    - Warning: This is irreversible. The video and image cache will be completely empty: all videos and images thereafter will need to be redownloaded and re-cached.
    
    - Usage:
    ```
    Celestial.shared.reset()
    ```
     
    */
    func reset()
}









// MARK: - MemoryCacheManagerProtocol

/// Specification for the mandatory properties that a cache manager must have.
/// For example, the Image and Video caches must have two NSCaches, one for encoded and the other for decoded items.
internal protocol MemoryCacheManagerProtocol: class {
    
    var encodedItemsCache: NSCache<AnyObject, AnyObject> { get }
    var decodedItemsCache: NSCache<AnyObject, AnyObject> { get }
    var lock: NSLock { get }
    var config: CacheControlConfiguration { get }
    
}



// MARK: - CacheControlConfiguration

/// Struct used in the setup of a Cache manager
/// For example, the Image and Video cache managers both specify a count and memory limit by default.
/// However, these values can be changed at a later time without using this Struct. This is merely for inittialization.
internal struct CacheControlConfiguration {
    let countLimit: Int
    let memoryLimit: Int
    
    static let defaultCountLimit: Int = 100 // 100 images
    static let defaultMemoryLimit: Int = 100.megabytes // 100 MB
    
    static let defaultConfig = CacheControlConfiguration(countLimit: CacheControlConfiguration.defaultCountLimit,
                                                         memoryLimit: CacheControlConfiguration.defaultMemoryLimit)
}




// MARK: - MemoryCacheProtocol

/// Generic specifications/functions that both Image and Video cache managers must implement.
internal protocol MemoryCacheProtocol: class {
    
    associatedtype T
    
    // Returns the image/video associated with a given url string
    func item(for urlString: String) -> T?
    
    // Inserts the image/video of the specified url string in the cache
    func store(_ item: T?, with urlString: String)
    
    // Removes the image/video of the specified url string in the cache
    func removeItem(at urlString: String)
    
    // Removes all images/videos from the cache
    func clearAllItems()
    
    // Set the total number of items that can be saved.
    // Note this is not an explicit limit. See Apple documentation
    func setCacheItemLimit(_ value: Int)
    
    // Set the total cost in MB that can be saved.
    // Note this is not an explicit limit. See Apple documentation
    func setCacheCostLimit(numMegabytes: Int)
    
    // Accesses the value associated with the given key for reading and writing
    subscript(_ urlString: String) -> T? { get set}
}
