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
        
    }
}





// MARK: -  ImageCacheProtocol

extension Celestial: CelestialCacheProtocol {
    
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
    public func video(for urlString: String) -> OriginalVideoData? {
        return VideoCache.shared.item(for: urlString)
    }

    /// Caches the specified video data, its mime type and file extension using the `OriginalVideoData` struct.
    /// - Parameter video: The `OriginalVideoData` object which contains the Data of the video, the mime type and file extension of the original URL . This is necessary for rebuilding the video after caching.
    /// - Parameter urlString: The absolute string of the URL, which will be used as the key.
    /// Usage:
    /// ````
    ///     let originalVideoData(videoData: <your value>, mimeType: <Your URL.mimeType()>, fileExtension: <Your URL.pathExtension>)
    ///     let urlString = <Your URL.absoluteString>
    ///     Celestial.shared.store(video: originalVideoData, with: urlString)
    /// ````
    public func store(video: OriginalVideoData?, with urlString: String) {
        VideoCache.shared.store(video, with: urlString)
    }
    
    /// Evicts the `OriginalVideoData` at the specified url string from the Video cache.
    /// - Warning: This is irreversible. The cache will no longer contain a value for this key, thus requiring the video to be redownloaded and re-cached.
    /// - Parameter urlString: The absolute string of the URL, which will be used as the key.
    /// Usage:
    /// ````
    ///     let urlString = <your URL.absoluteString>
    ///     Celestial.shared.removeVideo(at: urlString)
    /// ````
    public func removeVideo(at urlString: String) {
        VideoCache.shared.removeItem(at: urlString)
    }
    
    /// Evicts all items from the Video cache.
    /// - Warning: This is irreversible. The video cache will be completely empty: all videos thereafter will need to be redownloaded and re-cached.
    /// - Usage:
    /// ````
    ///     Celestial.shared.clearAllVideos()
    /// ````
    public func clearAllVideos() {
        VideoCache.shared.clearAllItems()
    }
    
    
    
    
    
    

    
    
    
    
    
    
    
    
    
    // Image
    
    /// Returns a UIImage using the url as the key.
    /// - Parameter urlString: The absolute string of the URL which will be used as the key.
    /// Usage:
    /// ````
    ///     let urlString = <Your URL.absoluteString>
    ///     guard let image = Celestial.shared.image(for: urlString) else {
    ///        return
    ///     }
    /// ````
    /// - Returns: A `UIImage ` at the specified urlString.
    public func image(for urlString: String) -> UIImage? {
        return ImageCache.shared.item(for: urlString)
    }
    
    /// Caches the UIImage .
    /// - Parameter image: The `UIImage` to be cached.
    /// - Parameter urlString: The absolute string of the URL, which will be used as the key.
    /// Usage:
    /// ````
    ///     let downloadImage = <image from URLSession/dataTask>
    ///     let urlString = <Your URL.absoluteString>
    ///     Celestial.shared.store(video: originalVideoData, with: urlString)
    /// ````
    public func store(image: UIImage?, with urlString: String) {
        ImageCache.shared.store(image, with: urlString)
    }
    
    /// Evicts the `UIImage` at the specified url string from the Image cache.
    /// - Warning: This is irreversible. The cache will no longer contain a value for this key, thus requiring the image to be redownloaded and re-cached.
    /// - Parameter urlString: The absolute string of the URL, which will be used as the key.
    /// Usage:
    /// ````
    ///     let urlString = <your URL.absoluteString>
    ///     Celestial.shared.removeImage(at: urlString)
    /// ````
    public func removeImage(at urlString: String) {
        ImageCache.shared.removeItem(at: urlString)
    }
    
    /// Evicts all items from the Image cache.
    /// - Warning: This is irreversible. The image cache will be completely empty: all images thereafter will need to be redownloaded and re-cached.
    /// - Usage:
    /// ````
    ///     Celestial.shared.clearAllImages()
    /// ````
    public func clearAllImages() {
        ImageCache.shared.clearAllItems()
    }
    
    
    
    
    
    
    
    
    
    
    // MISC.
    
    /// Sets the maximum number of items that can be stored in either the video or image cache.
    /// e.g., specifying `100` for videoCache means at max, 100 videos may be stored.
    /// However, according to the Apple documentation, this is not a strict limit.
    /// Passing in nil for either argument will leave its respective cache unaffected and use the previous value
    /// or default value.
    /// - Parameter videoCache: Integer value representing the number of items the Video cache should be limited to.
    /// - Parameter imageCache: Integer value representing the number of items the Image cache should be limited to.
    /// - Usage:
    /// ````
    ///     Celestial.shared.setCacheItemLimit(videoCache: 100, imageCache: 100)
    /// ````
    func setCacheItemLimit(videoCache: Int?, imageCache: Int?) {
        if let videoCacheLimit = videoCache {
            VideoCache.shared.setCacheItemLimit(videoCacheLimit)
        }
        if let imageCacheLimit = imageCache {
            ImageCache.shared.setCacheItemLimit(imageCacheLimit)
        }
    }
    
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
    /// ````
    ///     Celestial.shared.setCacheItemLimit(videoCache: Int.OneGigabyte, imageCache: Int.OneMegabyte * 100)
    /// ````
    public func setCacheCostLimit(videoCache: Int?, imageCache: Int?) {
        if let videoCacheLimit = videoCache {
            VideoCache.shared.setCacheCostLimit(numMegabytes: videoCacheLimit)
        }
        if let imageCacheLimit = imageCache {
            ImageCache.shared.setCacheCostLimit(numMegabytes: imageCacheLimit)
        }
    }
    
    /// Sets an internal Boolean value which determines whether debug statements will be printed to console.
    /// For example, information regarding when the image or video cache is evicting items for memory space
    /// will be printed.
    /// It is set to `false` by default
    /// - Parameter on: Boolean value which will determine if debug statements will be printed to console.
    /// - Usage:
    /// ````
    ///     Celestial.shared.setDebugMode(on: true)
    /// ````
    public func setDebugMode(on: Bool) {
        debugModeIsActive = on
    }
    
    /// Evicts all items from both the video and image caches.
    /// - Warning: This is irreversible. The video and image cache will be completely empty: all videos and images thereafter will need to be redownloaded and re-cached.
    /// - Usage:
    /// ````
    ///     Celestial.shared.reset()
    /// ````
    public func reset() {
        VideoCache.shared.clearAllItems()
        ImageCache.shared.clearAllItems()
    }
}
