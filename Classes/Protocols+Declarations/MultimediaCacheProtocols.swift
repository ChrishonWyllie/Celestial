//
//  MultimediaCacheProtocols.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import UIKit.UIImage

internal protocol CelestialCacheProtocol: class {
    
    // Returns the image associated with a given url string
    func image(for urlString: String) -> UIImage?
    // Inserts the image of the specified url string in the cache
    func store(_ image: UIImage?, with urlString: String)
    // Removes the image of the specified url string in the cache
    func removeImage(at urlString: String)
    // Removes all images from the cache
    func clearAllImages()
    // Accesses the value associated with the given key for reading and writing
    subscript(_ urlString: String) -> UIImage? { get set }
    
    
    
    // Video caching TBD
}





/// Generic protocol that both VideoCache and ImageCache must implement.
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
    
    // Set the total cost of items that can be saved.
    // Note this is not an explicit limit. See Apple documentation
    func setCacheCostLimit(_ value: Int)
    
    // Accesses the value associated with the given key for reading and writing
    subscript(_ urlString: String) -> T? { get set}
}
