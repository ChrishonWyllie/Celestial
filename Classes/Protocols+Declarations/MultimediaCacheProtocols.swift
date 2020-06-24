//
//  MultimediaCacheProtocols.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import UIKit.UIImage

// MARK: - MultimediaCachePolicy

/// Enum for specifying if the image or video should be cached or not.
/// Used as optional argument in the URLImageView and CachableAVPlayerItem initializer.
public enum MultimediaCachePolicy {
    case allow
    case notAllowed
}


// MARK: - CelestialCacheProtocol

/// Specification for the functions that the Celestial cache manager must follow
/// Examples include basic CRUD functions
internal protocol CelestialCacheProtocol: class {
    
    // Video
    
    /// Returns information for video data using the url as the key.
    /// - Parameter urlString: The absolute string of the URL which will be used as the key.
    /// Usage:
    /// ````
    ///     let urlString = <Your URL.absoluteString>
    ///     guard let originalVideoData = Celestial.shared.video(for: urlString) else {
    ///        return
    ///     }
    /// ````
    /// - Returns: An `OriginalVideoData ` object at the specified urlString, which contains the data of the video file, the mime type and file extension of the original URL.
    func video(for urlString: String) -> OriginalVideoData?
    
    /// Caches the specified video data, its mime type and file extension using the `OriginalVideoData` struct.
    /// - Parameter video: The `OriginalVideoData` object which contains the Data of the video, the mime type and file extension of the original URL . This is necessary for rebuilding the video after caching.
    /// - Parameter urlString: The absolute string of the URL, which will be used as the key.
    /// Usage:
    /// ````
    ///     let originalVideoData(videoData: <your value>, mimeType: <Your URL.mimeType()>, fileExtension: <Your URL.pathExtension>)
    ///     let urlString = <Your URL.absoluteString>
    ///     Celestial.shared.store(video: originalVideoData, with: urlString)
    /// ```
    func store(video: OriginalVideoData?, with urlString: String)
    
    /// Evicts the `OriginalVideoData` at the specified url string from the Video cache.
    /// - Warning: This is irreversible. The cache will no longer contain a value for this key, thus requiring the video to be redownloaded and re-cached.
    /// - Parameter urlString: The absolute string of the URL, which will be used as the key.
    /// Usage:
    /// ```
    ///     let urlString = <your URL.absoluteString>
    ///     Celestial.shared.removeVideo(at: urlString)
    /// ```
    func removeVideo(at urlString: String)
    
    
    /// Evicts all items from the Video cache.
    /// - Warning: This is irreversible. The video cache will be completely empty: all videos thereafter will need to be redownloaded and re-cached.
    /// - Usage:
    /// ```
    ///     Celestial.shared.clearAllVideos()
    /// ```
    func clearAllVideos()
    
    
    
    
    // Image
    
    /// Returns a UIImage using the url as the key.
    /// - Parameter urlString: The absolute string of the URL which will be used as the key.
    /// Usage:
    /// ```
    ///     let urlString = <Your URL.absoluteString>
    ///     guard let image = Celestial.shared.image(for: urlString) else {
    ///        return
    ///     }
    /// ```
    /// - Returns: A `UIImage ` at the specified urlString.
    func image(for urlString: String) -> UIImage?
    
    /// Caches the UIImage .
    /// - Parameter image: The `UIImage` to be cached.
    /// - Parameter urlString: The absolute string of the URL, which will be used as the key.
    /// Usage:
    /// ```
    ///     let downloadImage = <image from URLSession/dataTask>
    ///     let urlString = <Your URL.absoluteString>
    ///     Celestial.shared.store(video: originalVideoData, with: urlString)
    /// ```
    func store(image: UIImage?, with urlString: String)
    
    /// Evicts the `UIImage` at the specified url string from the Image cache.
    /// - Warning: This is irreversible. The cache will no longer contain a value for this key, thus requiring the image to be redownloaded and re-cached.
    /// - Parameter urlString: The absolute string of the URL, which will be used as the key.
    /// Usage:
    /// ```
    ///     let urlString = <your URL.absoluteString>
    ///     Celestial.shared.removeImage(at: urlString)
    /// ```
    func removeImage(at urlString: String)
    
    /// Evicts all items from the Image cache.
    /// - Warning: This is irreversible. The image cache will be completely empty: all images thereafter will need to be redownloaded and re-cached.
    /// - Usage:
    /// ```
    ///     Celestial.shared.clearAllImages()
    /// ```
    func clearAllImages()
    
    
    
    
    
    
    
    /// Sets the maximum number of items that can be stored in either the video or image cache.
    /// e.g., specifying `100` for videoCache means at max, 100 videos may be stored.
    /// However, according to the Apple documentation, this is not a strict limit.
    /// Passing in nil for either argument will leave its respective cache unaffected and use the previous value
    /// or default value.
    /// - Parameter videoCache: Integer value representing the number of items the Video cache should be limited to.
    /// - Parameter imageCache: Integer value representing the number of items the Image cache should be limited to.
    /// - Usage:
    /// ```
    ///     Celestial.shared.setCacheItemLimit(videoCache: 100, imageCache: 100)
    /// ```
    func setCacheItemLimit(videoCache: Int?, imageCache: Int?)
    
    /// Sets the maximum cost of items that can be stored in either the video or image cache.
    /// NOTE: This value is in number of bytes. Use `Int.OneMegabyte (1024 * 1024) * <your value>` or `Int.OneGigabyte (1024 * 1024 * 1000) * <your value>`
    /// This means that with each additional item stored in the cache, the available space will decrease by the size of the item.
    /// e.g., if the cost limit is set to 100 MB (104857600 bytes)
    /// However, according to the Apple documentation, this is not a strict limit.
    /// Passing in nil for either argument will leave its respective cache unaffected and use the previous value
    /// or default value.
    /// - Parameter videoCache: Integer value representing the number of bytes the Video cache should be limited to.
    /// - Parameter imageCache: Integer value representing the number of bytes the Image cache should be limited to.
    /// - Usage:
    /// ```
    ///     Celestial.shared.setCacheItemLimit(videoCache: Int.OneGigabyte, imageCache: Int.OneMegabyte * 100)
    /// ```
    func setCacheCostLimit(videoCache: Int?, imageCache: Int?)
    
    /// Sets an internal Boolean value which determines whether debug statements will be printed to console.
    /// For example, information regarding when the image or video cache is evicting items for memory space
    /// will be printed.
    /// It is set to `false` by default
    /// - Parameter on: Boolean value which will determine if debug statements will be printed to console.
    /// - Usage:
    /// ```
    ///     Celestial.shared.setDebugMode(on: true)
    /// ```
    func setDebugMode(on: Bool)
    
    /// Evicts all items from both the video and image caches.
    /// - Warning: This is irreversible. The video and image cache will be completely empty: all videos and images thereafter will need to be redownloaded and re-cached.
    /// - Usage:
    /// ```
    ///     Celestial.shared.reset()
    /// ```
    func reset()
}











// MARK: - CacheManagerProtocol

/// Specification for the mandatory properties that a cache manager must have.
/// For example, the Image and Video caches must have two NSCaches, one for encoded and the other for decoded items.
internal protocol CacheManagerProtocol: class {
    
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




// MARK: - CacheProtocol

/// Generic specifications/functions that both Image and Video cache managers must implement.
internal protocol CacheProtocol: class {
    
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
