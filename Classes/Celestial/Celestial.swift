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

extension Celestial: ImageCacheProtocol {
    
    public func image(for urlString: String) -> UIImage? {
        return ImageCache.shared.image(for: urlString)
    }
    
    public func store(_ image: UIImage?, with urlString: String) {
        ImageCache.shared.store(image, with: urlString)
    }
    
    public func removeImage(at urlString: String) {
        ImageCache.shared.removeImage(at: urlString)
    }
    
    public func clearAllImages() {
        ImageCache.shared.clearAllImages()
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
