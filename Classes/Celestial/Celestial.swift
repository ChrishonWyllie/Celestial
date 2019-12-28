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
    
    public func image(for urlString: String) -> UIImage? {
        return ImageCache.shared.item(for: urlString)
    }
    
    public func store(_ image: UIImage?, with urlString: String) {
        ImageCache.shared.store(image, with: urlString)
    }
    
    public func removeImage(at urlString: String) {
        ImageCache.shared.removeItem(at: urlString)
    }
    
    public func clearAllImages() {
        ImageCache.shared.clearAllItems()
    }
    
    public subscript(urlString: String) -> UIImage? {
        get {
            return ImageCache.shared[urlString]
        }
        set {
            return ImageCache.shared[urlString] = newValue
        }
    }
    
}
