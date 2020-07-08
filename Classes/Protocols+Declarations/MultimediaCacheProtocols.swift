//
//  MultimediaCacheProtocols.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import UIKit.UIImage

// MARK: - MultimediaCachePolicy

/// Enum for specifying if the image or video should be cached or not.
/// Used as optional argument in the URLImageView, URLVideoPlayerView and CachableAVPlayerItem initializer.
@objc public enum MultimediaCachePolicy: Int {
    case allow = 0
    case notAllowed
}

// MARK: - CelestialVideoCachingProtocol

/// Forces conformance for implementing functions related to video caching
internal protocol CelestialVideoCachingProtocol: class {
    
    /**
     Returns a boolean value of whether a video exists

    - Parameters:
       - sourceURL: The url of the resource that has been requested
       - cacheLocation: Determines where to look for the cached item if it exists
     
    - Returns:
       - A boolean value of whether the requested resource has been previously cached
    */
    func videoExists(for sourceURL: URL, cacheLocation: DownloadCompletionCacheLocation) -> Bool
    
    
    
    
    
    
    /**
     Returns information for cached video data in memory

    - Parameters:
       - sourceURLString: The url of the resource that has been requested
     
    - Usage:
    ```
    let urlString = <Your URL.absoluteString>
    guard let originalVideoData = Celestial.shared.videoData(for: urlString) else {
        return
    }
    ```
     
    - Returns: An `MemoryCachedVideoData ` object at the specified urlString, which contains the data of the video file, the mime type and file extension of the original URL.
    */
    func videoData(for sourceURLString: String) -> MemoryCachedVideoData?
    
    
    
    
    
    
    
    /**
     Returns cached video from file system

    - Parameters:
       - sourceURL: The url of the resource that has been requested
     
    - Usage:
    ```
    let sourceURL = <Your URL>
    guard let originalVideoData = Celestial.shared.videoURL(for: sourceURL) else {
        return
    }
    ```
     
    - Returns: A URL pointing to the video in file system.
    */
    func videoURL(for sourceURL: URL) -> URL?
    
    
    
    
    
    
    
    /**
     Caches the specified video data, its mime type and file extension using the `MemoryCachedVideoData` struct.

    - Parameters:
       - videoData: The `MemoryCachedVideoData` object which contains the Data of the video, the mime type and file extension of the original URL . This is necessary for rebuilding the video after caching.
       - sourceURLString: The url of the resource that has been requested
     
    - Usage:
    ```
    let url = <Your URL.absoluteString>
    let originalVideoData(videoData: <your value>, mimeType: <Your URL.mimeType()>, fileExtension: <Your URL.pathExtension>)
    Celestial.shared.store(video: originalVideoData, with: urlString)
    ```
     
    */
    func store(videoData: MemoryCachedVideoData?, with sourceURLString: String)
    
    
    
    
    
    /**
     Caches the specified video url

    - Parameters:
       - videoURL: The url of the video to be cached. This video URL must not be an external url. It must already exist on file, such as in a temporary directory after a `URLSessionDownloadTask` completes
       - sourceURL: The url of the resource that has been requested
       - completion: Executes completion block with a URL pointing to a compressed video
     
    - Usage:
    ```
    let videoURL = <Your URL from recently finished download>
    let sourceURL = <Your URL from external server>
    Celestial.shared.storeVideoURL(videoURL, with: sourceURL) { (cachedURL) in
        ...
    }
    ```
     
    */
    func storeVideoURL(_ videoURL: URL, withSourceURL sourceURL: URL, completion: @escaping (URL?) -> ())
    
    
    
    
    /**
     Evicts the `MemoryCachedVideoData` at the specified url from the Video cache.
     
    - Warning: This is irreversible. The cache will no longer contain a value for this key, thus requiring the video to be redownloaded and re-cached.
     
    - Parameters:
       - sourceURLString: The url of the resource that has been requested
     
    - Usage:
    ```
    let sourceURLString = <Your URL.absoluteSring>
    Celestial.shared.removeVideoData(using: sourceURLString)
    ```
     
    */
    func removeVideoData(using sourceURLString: String)
    
    
    
    
    
    
    
    
    /**
     Evicts the video  at the specified url from the Video cache.
     
    - Warning: This is irreversible. The cache will no longer contain a value for this key, thus requiring the video to be redownloaded and re-cached.
     
    - Parameters:
       - sourceURL: The url of the resource that has been requested
     
    - Usage:
    ```
    let sourceURL = <Your URL>
    Celestial.shared.removeVideoURL(using: sourceURL)
    ```
     
    - Returns:
        A Boolean value of whether all videos represented by the sourceURL has been deleted
    */
    func removeVideoURL(using sourceURL: URL) -> Bool
    
    
    
    
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
       - sourceURL: The url of the resource that has been requested
       - cacheLocation: Determines where to look for the cached item if it exists
     
    - Returns:
       - A boolean value of whether the requested resource has been previously cached
    */
    func imageExists(for sourceURL: URL, cacheLocation: DownloadCompletionCacheLocation) -> Bool
    
    
    
    
    
    
    /**
     Returns a cached UIImage using the url as the key

    - Parameters:
       - sourceURLString: The url of the resource that has been requested
    
    - Usage:
    ```
    let urlString = <Your URL.absoluteString>
    guard let image = Celestial.shared.image(for: urlString) else {
        return
    }
    ```
     
    - Returns:
       - A `UIImage` at the specified url.absoluteString.
    */
    func image(for sourceURLString: String) -> UIImage?
    
    
    
    
    
    
    
    
    
    
    
    /**
     Returns a cached image URL using the source url as the key

    - Parameters:
       - sourceURL: The URL of the resource that has been requested
       - pointSize: The CGrect.CGSize of the image that will be displated
    
    - Usage:
    ```
    let sourceURL = <Your URL>
    guard let image = Celestial.shared.imageURL(for: sourceURL) else {
        return
    }
    ```
     
    - Returns:
       - A URL pointing to the image cached image in file system that is the same point size as the one requested
    */
    func imageURL(for sourceURL: URL, pointSize: CGSize) -> URL?
    
    
    
    
    
    
    
    
    /**
     Caches the UIImage

    - Parameters:
       - image: The `UIImage` to be cached in memory
       - sourceURLString: The url of the resource that has been requested
    
    - Usage:
    ```
    let downloadImage = <image from URLSessionDownloadTask>
    let urlString = <Your URL.absoluteString>
    Celestial.shared.store(image: downloadedImage, with: urlString)
    ```
     
    */
    func store(image: UIImage?, with sourceURLString: String)
    
    
    
    
    
    
    
    
    
    
    
    /**
     Caches the downloaded image URL

    - Parameters:
       - imageURL: The local URL of the image to be cached to file system
       - sourceURL: The URL of the requested resource
       - pointSize: The iOS point size of the image. Will be used to store and retrieve the same image at different sizes
    
    - Usage:
    ```
    let downloadImageURL = <image URL from URLSessionDownloadTask>
    let sourceURL = <Your URL>
    let pointSize = <Your desired point size, possibly after layout finishes>
    Celestial.shared.storeImageURL(downloadedImageURL, with: sourceURL, pointSize: pointSize)
    ```
     
    - Returns:
        A `UIImage` that has been resized to the desired iOS point size
    */
    func storeImageURL(_ temporaryFileURL: URL, withSourceURL sourceURL: URL, pointSize: CGSize) -> UIImage?
    
    
    
    
    
    
    
    
    /**
     Evicts the `UIImage` at the specified url string from the in-memory Image cache.

    - Warning: This is irreversible. The in-memory cache will no longer contain a value for this key, thus requiring the image to be redownloaded and re-cached.
     
    - Parameters:
       - sourceURLString: The url of the resource that has been requested
    
    - Usage:
    ```
    let urlString = <Your URL>
    Celestial.shared.removeImage(using: urlString)
    ```
     
    */
    func removeImage(using sourceURLString: String)
    
    
    
    
    
    
    
    /**
     Evicts the image file at the specified url from the file system

    - Warning: This is irreversible. The cache will no longer contain a value for this key, thus requiring the image to be redownloaded and re-cached.
     
    - Parameters:
       - sourceURL: The URL of the resource that has been requested
    
    - Usage:
    ```
    let urlString = <your URL>
    guard let url = URL(string: urlString) else {
        return
    }
    
    Celestial.shared.removeImageURL(using: url)
    ```
     
    - Returns:
        A Boolean value of whether all videos represented by the sourceURL has been deleted
    */
    func removeImageURL(using sourceURL: URL) -> Bool
    
    
    
    
    
    
    
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
        - sourceURL: The URL of the resource that has been requested
       
    - Usage:
    ```
    let urlString = <your URL>
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
        - sourceURL: The URL of the resource that has been requested
       
    - Usage:
    ```
    let urlString = <your URL>
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
        - sourceURL: The URL of the resource that has been requested
       
    - Usage:
    ```
    let urlString = <your URL>
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
        - sourceURL: The URL of the resource that has been requested
       
    - Usage:
    ```
    let urlString = <your URL>
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
        - sourceURL: The URL of the resource that has been requested
     
    - Usage:
    ```
    let urlString = <your URL>
    guard let url = URL(string: urlString) else {
        return
    }
    Celestial.shared.cancelDownload(for: url)
    ```
     
    */
    func cancelDownload(for sourceURL: URL)
    
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
    Celestial.shared.setCacheItemLimit(videoCache: 100, imageCache: 100)
    ```
     
    */
    func setCacheItemLimit(videoCache: Int?, imageCache: Int?)
    
    
    
    
    
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
    Celestial.shared.setCacheItemLimit(videoCache: Int.OneGigabyte, imageCache: Int.OneMegabyte * 100)
    ```
     
    */
    func setCacheCostLimit(videoCache: Int?, imageCache: Int?)
    
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
