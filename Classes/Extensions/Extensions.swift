//
//  Extensions.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import UIKit

// MARK: - UIImage

internal extension UIImage {

    func decodedImage() -> UIImage {
        guard let cgImage = cgImage else { return self }
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: cgImage.bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        context?.draw(cgImage, in: CGRect(origin: .zero, size: size))
        guard let decodedImage = context?.makeImage() else { return self }
        return UIImage(cgImage: decodedImage)
    }
    
    // Rough estimation of how much memory image uses in bytes
    var diskSize: Int {
        guard let cgImage = cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}










// MARK: - UIImageView

public extension UIImageView {
    
}






// MARK: - Int

internal extension Int {
    static let OneMegabyte = 1024 * 1024
    static let OneGigabyte = OneMegabyte * 1000
}





// MARK: - Data

internal extension Data {
    
    var sizeInMB: Float {
        return Float(self.count) / Float(Int.OneMegabyte)
    }
    
}






// MARK: - URL

internal extension URL {
    
    func withScheme(_ scheme: String) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = scheme
        return components?.url
    }
    
}
