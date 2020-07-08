//
//  VideoCache.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import UIKit

internal final class VideoCache: NSObject, MemoryCacheManagerProtocol {
    
    // MARK: - Variables
    
    public static let shared = VideoCache(config: CacheControlConfiguration(countLimit: 100, memoryLimit: 400.megabytes))
    
    private(set) lazy var encodedItemsCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.name = "Encoded videos cache"
        cache.countLimit = config.countLimit
        cache.delegate = self
        return cache
    }()
    
    private(set) lazy var decodedItemsCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.name = "Decoded videos cache"
        cache.totalCostLimit = config.memoryLimit
        cache.delegate = self
        return cache
    }()
    
    private(set) var lock: NSLock = NSLock()
    
    private(set) var config: CacheControlConfiguration
    
    
    
    
    
    
    // MARK: - Initializers
    
    private init(config: CacheControlConfiguration = CacheControlConfiguration.defaultConfig) {
        self.config = config
    }
    
    private override init() {
        self.config = CacheControlConfiguration.defaultConfig
    }
    
}









// MARK: - VideoCacheProtocol

extension VideoCache: MemoryCacheProtocol {

    typealias T = MemoryCachedVideoData
    
    func item(for urlString: String) -> MemoryCachedVideoData? {

        lock.lock(); defer { lock.unlock() }
        // the best case scenario -> there is already decompressed decoded data in the cache
        if let decompressedMemoryCachedVideoData = decodedItemsCache.object(forKey: urlString as AnyObject) as? MemoryCachedVideoData {
            return decompressedMemoryCachedVideoData
        }

        // search for compressed data and decompress it.
        if let compressedMemoryCachedVideoData = encodedItemsCache.object(forKey: urlString as AnyObject) as? MemoryCachedVideoData {
            
            var cachedVideoData: Data!
            
            if #available(iOS 13.0, *) {
                do {
                    cachedVideoData = try (compressedMemoryCachedVideoData.videoData as NSData).decompressed(using: NSData.CompressionAlgorithm.lzfse) as Data
                } catch let error {
                    DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error getting decompressed Data from cache: \(error.localizedDescription)")
                    cachedVideoData = compressedMemoryCachedVideoData.videoData
                }
            } else {
                // Fallback on earlier versions
                cachedVideoData = compressedMemoryCachedVideoData.videoData
            }
            
            let decompressedMemoryCachedVideoData = MemoryCachedVideoData(videoData: cachedVideoData as Data,
                                                                  originalURLMimeType: compressedMemoryCachedVideoData.originalURLMimeType,
                                                                  originalURLFileExtension: compressedMemoryCachedVideoData.originalURLFileExtension)
            decodedItemsCache.setObject(decompressedMemoryCachedVideoData as AnyObject, forKey: urlString as AnyObject, cost: decompressedMemoryCachedVideoData.videoData.count)
            return decompressedMemoryCachedVideoData as MemoryCachedVideoData
        }

        return nil
    }

    func store(_ item: MemoryCachedVideoData?, with urlString: String) {
        guard let decompressedMemoryCachedVideoData = item else {
            // Store `nil` at this urlString
            // In other words, remove the video data at this key.
            return removeItem(at: urlString)
        }

        var cachedVideoData: Data!
        
        if #available(iOS 13.0, *) {
            do {
                cachedVideoData = try (decompressedMemoryCachedVideoData.videoData as NSData).compressed(using: NSData.CompressionAlgorithm.lzfse) as Data
            } catch let error {
                 DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error storing compressed Data from cache: \(error.localizedDescription)")
                cachedVideoData = decompressedMemoryCachedVideoData.videoData
            }
        } else {
            // Fallback on earlier versions
            cachedVideoData = decompressedMemoryCachedVideoData.videoData
        }
        
        let compressedMemoryCachedVideoData = MemoryCachedVideoData(videoData: cachedVideoData,
                                                            originalURLMimeType: decompressedMemoryCachedVideoData.originalURLMimeType,
                                                            originalURLFileExtension: decompressedMemoryCachedVideoData.originalURLFileExtension)
        lock.lock(); defer { lock.unlock() }
        
        encodedItemsCache.setObject(compressedMemoryCachedVideoData as AnyObject, forKey: urlString as AnyObject)
        decodedItemsCache.setObject(decompressedMemoryCachedVideoData as AnyObject, forKey: urlString as AnyObject, cost: decompressedMemoryCachedVideoData.videoData.count)
    }

    func removeItem(at urlString: String) {
        lock.lock(); defer { lock.unlock() }
        encodedItemsCache.removeObject(forKey: urlString as AnyObject)
        decodedItemsCache.removeObject(forKey: urlString as AnyObject)
    }
    
    func setCacheItemLimit(_ value: Int) {
        encodedItemsCache.countLimit = value
    }
    
    func setCacheCostLimit(numMegabytes: Int) {
        decodedItemsCache.totalCostLimit = numMegabytes * Int.OneMegabyte
    }

    func clearAllItems() {
        lock.lock(); defer { lock.unlock() }
        encodedItemsCache.removeAllObjects()
        decodedItemsCache.removeAllObjects()
    }

    subscript(urlString: String) -> MemoryCachedVideoData? {
        get {
            return item(for: urlString)
        }
        set {
            return store(newValue, with: urlString)
        }
    }

}








// MARK: - NSCacheDelegate
    
extension VideoCache: NSCacheDelegate {
    
    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        guard let videoData = obj as? MemoryCachedVideoData else {
            return
        }
        let messageOne = "[Video Cache] - cache with name: \"\(cache.name)\" and cost limit:    \(cache.totalCostLimit). In megabytes: \(cache.totalCostLimit.sizeInMB)"
        let messageTwo = "[Video Cache] - cache with name: \"\(cache.name)\" will evict object: \(videoData) with size: \(videoData.videoData.count) bytes.... in megabytes: \(videoData.videoData.count.sizeInMB)\n"
        DebugLogger.shared.addDebugMessage(messageOne)
        DebugLogger.shared.addDebugMessage(messageTwo)
    }
}
