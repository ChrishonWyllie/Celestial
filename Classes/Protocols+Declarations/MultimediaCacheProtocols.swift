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
    
    // Returns the video associated with a given url string
    func video(for urlString: String) -> OriginalVideoData?
    // Inserts the video of the specified url string in the cache
    func store(video: OriginalVideoData?, with urlString: String)
    // Removes the video of the specified url string in the cache
    func removeVideo(at urlString: String)
    // Removes all videos from the cache
    func clearAllVideos()
    
    func setCacheItemLimit(videoCache: Int?, imageCache: Int?)
    
    func setCacheCostLimit(videoCache: Int?, imageCache: Int?)
    
    
    
    // Image
    
    // Returns the image associated with a given url string
    func image(for urlString: String) -> UIImage?
    // Inserts the image of the specified url string in the cache
    func store(image: UIImage?, with urlString: String)
    // Removes the image of the specified url string in the cache
    func removeImage(at urlString: String)
    // Removes all images from the cache
    func clearAllImages()
    
    
    
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
