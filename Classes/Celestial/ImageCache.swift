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
    private lazy var imageCache: NSCache<AnyObject, AnyObject> = {
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
    private let config: Config

    struct Config {
        let countLimit: Int
        let memoryLimit: Int
        
        static let defaultMemoryLimit: Int = Int.OneMegabyte * 100 // 100 MB
        
        static let defaultConfig = Config(countLimit: 100, memoryLimit: Config.defaultMemoryLimit)
    }

    
    
    
    // MARK: - Initializers
    
    private init(config: Config = Config.defaultConfig) {
        self.config = config
    }
    
    private override init() {
        self.config = Config.defaultConfig
    }
    
}






// MARK: - ImageCacheProtocol

extension ImageCache: ImageCacheProtocol {
    
    func image(for urlString: String) -> UIImage? {
        
        lock.lock(); defer { lock.unlock() }
        // the best case scenario -> there is a decoded image
        if let decodedImage = decodedImageCache.object(forKey: urlString as AnyObject) as? UIImage {
            return decodedImage
        }
        
        // search for image data
        if let image = imageCache.object(forKey: urlString as AnyObject) as? UIImage {
            let decodedImage = image.decodedImage()
            decodedImageCache.setObject(image as AnyObject, forKey: urlString as AnyObject, cost: decodedImage.diskSize)
            return decodedImage
        }
        
        return nil
    }
    
    func store(_ image: UIImage?, with urlString: String) {
        guard let image = image else { return removeImage(at: urlString) }
        let decodedImage = image.decodedImage()

        lock.lock(); defer { lock.unlock() }
        
        imageCache.setObject(decodedImage, forKey: urlString as AnyObject)
        decodedImageCache.setObject(image as AnyObject, forKey: urlString as AnyObject, cost: decodedImage.diskSize)
    }
    
    func removeImage(at urlString: String) {
        lock.lock(); defer { lock.unlock() }
        imageCache.removeObject(forKey: urlString as AnyObject)
        decodedImageCache.removeObject(forKey: urlString as AnyObject)
    }
    
    func clearAllImages() {
        lock.lock(); defer { lock.unlock() }
        imageCache.removeAllObjects()
        decodedImageCache.removeAllObjects()
    }
    
    subscript(urlString: String) -> UIImage? {
        get {
            return image(for: urlString)
        }
        set {
            return store(newValue, with: urlString)
        }
    }

}
