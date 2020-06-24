//
//  VideoCache.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import UIKit

internal final class VideoCache: NSObject, CacheManagerProtocol {
    
    // MARK: - Variables
    
    public static let shared = VideoCache(config: CacheControlConfiguration(countLimit: 100, memoryLimit: 400.megabytes))
    
    private(set) lazy var encodedItemsCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.name = "Encoded items cache"
        cache.countLimit = config.countLimit
        cache.delegate = self
        return cache
    }()
    
    private(set) lazy var decodedItemsCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.name = "Decoded items cache"
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









// MARK: - ImageCacheProtocol

extension VideoCache: CacheProtocol {

    typealias T = OriginalVideoData
    
    func item(for urlString: String) -> OriginalVideoData? {

        lock.lock(); defer { lock.unlock() }
        // the best case scenario -> there is already decompressed decoded data in the cache
        if let cachedDecompressedOriginalVideoData = decodedItemsCache.object(forKey: urlString as AnyObject) as? OriginalVideoData {
            return cachedDecompressedOriginalVideoData
        }

        // search for compressed data and decompress it.
        if let cachedCompressedOriginalVideoData = encodedItemsCache.object(forKey: urlString as AnyObject) as? OriginalVideoData {
            do {
                let decompressedVideoData = try (cachedCompressedOriginalVideoData.videoData as NSData).decompressed(using: NSData.CompressionAlgorithm.lzfse)
                let decompressedOriginalVideoData = OriginalVideoData(videoData: decompressedVideoData as Data,
                                                                      originalURLMimeType: cachedCompressedOriginalVideoData.originalURLMimeType,
                                                                      originalURLFileExtension: cachedCompressedOriginalVideoData.originalURLFileExtension)
                decodedItemsCache.setObject(decompressedOriginalVideoData as AnyObject, forKey: urlString as AnyObject, cost: decompressedOriginalVideoData.videoData.count)
                return decompressedOriginalVideoData as OriginalVideoData
            } catch let error {
                print("Error getting decompressed Data from cache: \(error.localizedDescription)")
                return nil
            }
        }

        return nil
    }

    func store(_ item: OriginalVideoData?, with urlString: String) {
        guard let decompressedOriginalVideoData = item else {
            // Store `nil` at this urlString
            // In other words, remove the video data at this key.
            return removeItem(at: urlString)
        }

        do {
            let compressedData = try (decompressedOriginalVideoData.videoData as NSData).compressed(using: NSData.CompressionAlgorithm.lzfse)
            let compressedOriginalVideoData = OriginalVideoData(videoData: compressedData as Data,
                                                                originalURLMimeType: decompressedOriginalVideoData.originalURLMimeType,
                                                                originalURLFileExtension: decompressedOriginalVideoData.originalURLFileExtension)
            lock.lock(); defer { lock.unlock() }
            
            encodedItemsCache.setObject(compressedOriginalVideoData as AnyObject, forKey: urlString as AnyObject)
            decodedItemsCache.setObject(decompressedOriginalVideoData as AnyObject, forKey: urlString as AnyObject, cost: decompressedOriginalVideoData.videoData.count)
        } catch let error {
            print("Error storing compressed Data from cache: \(error.localizedDescription)")
        }
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

    subscript(urlString: String) -> OriginalVideoData? {
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
        guard let videoData = obj as? OriginalVideoData else {
            return
        }
        let messageOne = "[Video Cache] - cache with name: \"\(cache.name)\" and cost limit:    \(cache.totalCostLimit). In megabytes: \(cache.totalCostLimit.sizeInMB)"
        let messageTwo = "[Video Cache] - cache with name: \"\(cache.name)\" will evict object: \(videoData) with size: \(videoData.videoData.count) bytes.... in megabytes: \(videoData.videoData.count.sizeInMB)\n"
        DebugLogger.shared.addDebugMessage(messageOne)
        DebugLogger.shared.addDebugMessage(messageTwo)
    }
}
