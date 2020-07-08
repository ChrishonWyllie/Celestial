//
//  ImageCache.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import UIKit

internal final class ImageCache: NSObject, MemoryCacheManagerProtocol {

    // MARK: - Variables
    
    public static let shared = ImageCache(config: CacheControlConfiguration(countLimit: 100, memoryLimit: 200.megabytes))
    
    // 1st level cache, that contains encoded images
    private(set) lazy var encodedItemsCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.name = "Encoded images cache"
        cache.countLimit = config.countLimit
        cache.delegate = self
        return cache
    }()
    
    // 2nd level cache, that contains decoded images
    private(set) lazy var decodedItemsCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.name = "Decoded images cache"
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

extension ImageCache: MemoryCacheProtocol {

    typealias T = UIImage
    
    func item(for urlString: String) -> UIImage? {

        lock.lock(); defer { lock.unlock() }
        // the best case scenario -> there is a decoded image
        if let decodedImage = decodedItemsCache.object(forKey: urlString as AnyObject) as? UIImage {
            return decodedImage
        }

        // search for image data
        if let image = encodedItemsCache.object(forKey: urlString as AnyObject) as? UIImage {
            let decodedImage = image.decodedImage()
            decodedItemsCache.setObject(decodedImage as AnyObject, forKey: urlString as AnyObject, cost: decodedImage.diskSize)
            return decodedImage
        }

        return nil
    }

    func store(_ item: UIImage?, with urlString: String) {
        guard let image = item else {
            // Store `nil` at this urlString
            // In other words, remove the image at this key.
            return removeItem(at: urlString)
        }
        
        let decodedImage = image.decodedImage()

        lock.lock(); defer { lock.unlock() }

        encodedItemsCache.setObject(decodedImage, forKey: urlString as AnyObject)
        decodedItemsCache.setObject(image as AnyObject, forKey: urlString as AnyObject, cost: decodedImage.diskSize)
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

    subscript(urlString: String) -> UIImage? {
        get {
            return item(for: urlString)
        }
        set {
            return store(newValue, with: urlString)
        }
    }

}
    






// MARK: - NSCacheDelegate
    
extension ImageCache: NSCacheDelegate {
    
    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        guard let image = obj as? UIImage else {
            return
        }
        
        let messageOne = "[Video Cache] - cache with name: \"\(cache.name)\" and cost limit:    \(cache.totalCostLimit). In megabytes: \(cache.totalCostLimit.sizeInMB)"
        let messageTwo = "[Video Cache] - cache with name: \"\(cache.name)\" will evict object: \(image) with size: \(image.diskSize) bytes.... in megabytes: \(image.diskSize.sizeInMB)\n"
        DebugLogger.shared.addDebugMessage(messageOne)
        DebugLogger.shared.addDebugMessage(messageTwo)
    }
}
