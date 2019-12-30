//
//  Celestial.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import UIKit

public final class Celestial: NSObject {
    
    public static let shared = Celestial()
    
    
    
    
    
    // MARK: - Initializers
    
    private override init() {
        
    }
}





// MARK: -  ImageCacheProtocol

extension Celestial: CelestialCacheProtocol {
    
    // Video
    
    public func video(for urlString: String) -> OriginalVideoData? {
        return VideoCache.shared.item(for: urlString)
    }

    public func store(video: OriginalVideoData?, with urlString: String) {
        VideoCache.shared.store(video, with: urlString)
    }
    
    public func removeVideo(at urlString: String) {
        VideoCache.shared.removeItem(at: urlString)
    }
    
    public func clearAllVideos() {
        VideoCache.shared.clearAllItems()
    }
    

    
    
    func setCacheItemLimit(videoCache: Int?, imageCache: Int?) {
        if let videoCacheLimit = videoCache {
            VideoCache.shared.setCacheItemLimit(videoCacheLimit)
        }
        if let imageCacheLimit = imageCache {
            ImageCache.shared.setCacheItemLimit(imageCacheLimit)
        }
    }
    
    func setCacheCostLimit(videoCache: Int?, imageCache: Int?) {
        if let videoCacheLimit = videoCache {
            VideoCache.shared.setCacheCostLimit(numMegabytes: videoCacheLimit)
        }
        if let imageCacheLimit = imageCache {
            ImageCache.shared.setCacheCostLimit(numMegabytes: imageCacheLimit)
        }
    }
    
    
    
    
    
    
    
    // Image
    
    public func image(for urlString: String) -> UIImage? {
        return ImageCache.shared.item(for: urlString)
    }
    
    public func store(image: UIImage?, with urlString: String) {
        ImageCache.shared.store(image, with: urlString)
    }
    
    public func removeImage(at urlString: String) {
        ImageCache.shared.removeItem(at: urlString)
    }
    
    public func clearAllImages() {
        ImageCache.shared.clearAllItems()
    }
    
    
    
    
    
    
    
    public func reset() {
        VideoCache.shared.clearAllItems()
        ImageCache.shared.clearAllItems()
    }
}
