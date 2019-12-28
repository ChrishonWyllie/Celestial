//
//  ImageCache.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import UIKit

internal final class ImageCache: NSObject {

    // MARK: - Variables
    
    public static let shared = ImageCache()
    
    // 1st level cache, that contains encoded images
    private lazy var encodedImageCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.countLimit = config.countLimit
        return cache
    }()
    
    // 2nd level cache, that contains decoded images
    private lazy var decodedImageCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.totalCostLimit = config.memoryLimit
        return cache
    }()
    
    private let lock = NSLock()
    private let config: CacheControlConfiguration

    struct CacheControlConfiguration {
        let countLimit: Int
        let memoryLimit: Int
        
        static let defaultCountLimit: Int = 100 // 100 images
        static let defaultMemoryLimit: Int = Int.OneMegabyte * 100 // 100 MB
        
        static let defaultConfig = CacheControlConfiguration(countLimit: CacheControlConfiguration.defaultCountLimit, memoryLimit: CacheControlConfiguration.defaultMemoryLimit)
    }

    
    
    
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
        if let decodedImage = decodedImageCache.object(forKey: urlString as AnyObject) as? UIImage {
            return decodedImage
        }

        // search for image data
        if let image = encodedImageCache.object(forKey: urlString as AnyObject) as? UIImage {
            let decodedImage = image.decodedImage()
            decodedImageCache.setObject(image as AnyObject, forKey: urlString as AnyObject, cost: decodedImage.diskSize)
            return decodedImage
        }

        return nil
    }

    func store(_ item: UIImage?, with urlString: String) {
        guard let image = item else { return removeItem(at: urlString) }
        let decodedImage = image.decodedImage()

        lock.lock(); defer { lock.unlock() }

        encodedImageCache.setObject(decodedImage, forKey: urlString as AnyObject)
        decodedImageCache.setObject(image as AnyObject, forKey: urlString as AnyObject, cost: decodedImage.diskSize)
    }

    func removeItem(at urlString: String) {
        lock.lock(); defer { lock.unlock() }
        encodedImageCache.removeObject(forKey: urlString as AnyObject)
        decodedImageCache.removeObject(forKey: urlString as AnyObject)
    }
    
    func setCacheItemLimit(_ value: Int) {
        encodedImageCache.countLimit = value
    }
    
    func setCacheCostLimit(_ value: Int) {
        decodedImageCache.totalCostLimit = value
    }

    func clearAllItems() {
        lock.lock(); defer { lock.unlock() }
        encodedImageCache.removeAllObjects()
        decodedImageCache.removeAllObjects()
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
