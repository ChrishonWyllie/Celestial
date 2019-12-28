//
//  VideoCache.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import UIKit

internal final class VideoCache: NSObject, CacheManagerProtocol {
    
    // MARK: - Variables
    
    public static let shared = VideoCache(config: CacheControlConfiguration(countLimit: 100, memoryLimit: Int.OneGigabyte))
    
    private(set) lazy var encodedItemsCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.countLimit = config.countLimit
        return cache
    }()
    
    private(set) lazy var decodedItemsCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.totalCostLimit = config.memoryLimit
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

    typealias T = Data
    
    func item(for urlString: String) -> Data? {

        lock.lock(); defer { lock.unlock() }
        // the best case scenario -> there is already decompressed decoded data in the cache
        if let cachedDecodedData = decodedItemsCache.object(forKey: urlString as AnyObject) as? NSData {
            return cachedDecodedData as Data
        }

        // search for compressed data and decompress it.
        if let encodedData = encodedItemsCache.object(forKey: urlString as AnyObject) as? Data {
            do {
                let decodedData = try (encodedData as NSData).decompressed(using: NSData.CompressionAlgorithm.lzfse)
                decodedItemsCache.setObject(decodedData as AnyObject, forKey: urlString as AnyObject, cost: decodedData.count)
                return decodedData as Data
            } catch let error {
                print("Error getting decompressed Data from cache: \(error.localizedDescription)")
                return nil
            }
        }

        return nil
    }

    func store(_ item: Data?, with urlString: String) {
        guard let decompressedData = item else { return removeItem(at: urlString) }
        print("storing decompressed data with size: \(decompressedData.count). Size in mb: \((decompressedData as Data).sizeInMB)")
        do {
            let compressedData = try (decompressedData as NSData).compressed(using: NSData.CompressionAlgorithm.lzfse)
            lock.lock(); defer { lock.unlock() }
            
            print("memory limit: \(config.memoryLimit)")
            print("storing compressed data with size: \(compressedData.count). Size in mb: \((compressedData as Data).sizeInMB)")
            
            
            encodedItemsCache.setObject(compressedData, forKey: urlString as AnyObject)
            decodedItemsCache.setObject(decompressedData as AnyObject, forKey: urlString as AnyObject, cost: decompressedData.count)
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

    subscript(urlString: String) -> Data? {
        get {
            return item(for: urlString)
        }
        set {
            return store(newValue, with: urlString)
        }
    }

}
