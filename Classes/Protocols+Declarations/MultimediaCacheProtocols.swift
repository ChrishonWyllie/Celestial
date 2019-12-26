//
//  MultimediaCacheProtocols.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import UIKit.UIImage

public protocol VideoCacheProtocol: class {
    // TBD
}

public protocol ImageCacheProtocol: class {
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
}
