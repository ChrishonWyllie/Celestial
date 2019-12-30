//
//  ImageCache.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import UIKit

internal final class ImageCache: NSObject, CacheManagerProtocol {

    // MARK: - Variables
    
    public static let shared = ImageCache()
    
    // 1st level cache, that contains encoded images
    private(set) lazy var encodedItemsCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.countLimit = config.countLimit
        return cache
    }()
    
    // 2nd level cache, that contains decoded images
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

extension ImageCache: CacheProtocol {

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
            decodedItemsCache.setObject(image as AnyObject, forKey: urlString as AnyObject, cost: decodedImage.diskSize)
            return decodedImage
        }

        return nil
    }

    func store(_ item: UIImage?, with urlString: String) {
        guard let image = item else { return removeItem(at: urlString) }
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
