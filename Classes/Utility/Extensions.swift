//
//  Extensions.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import UIKit
import MobileCoreServices
import AVFoundation

// MARK: - UIImage

internal extension UIImage {

    func decodedImage() -> UIImage {
        guard let cgImage = cgImage else { return self }
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil,
                                width: Int(size.width), height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: cgImage.bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        context?.draw(cgImage, in: CGRect(origin: .zero, size: size))
        guard let decodedImage = context?.makeImage() else { return self }
        return UIImage(cgImage: decodedImage)
    }
    
    /// A rough estimation of how much memory this UIImage uses in bytes
    var diskSize: Int {
        guard let cgImage = cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
    
    func resize(width: CGFloat) -> UIImage? {
        let height = (width / self.size.width) * self.size.height
        return self.resize(size: CGSize(width: width, height: height))
    }

    func resize(height: CGFloat) -> UIImage? {
        let width = (height / self.size.height) * self.size.width
        return self.resize(size: CGSize(width: width, height: height))
    }

    func resize(size: CGSize) -> UIImage? {
        let widthRatio  = size.width / self.size.width
        let heightRatio = size.height / self.size.height
        var updateSize = size
        
        if (widthRatio > heightRatio) {
            updateSize = CGSize(width: self.size.width * heightRatio, height: self.size.height * heightRatio)
        } else if heightRatio > widthRatio {
            updateSize = CGSize(width: self.size.width * widthRatio,  height: self.size.height * widthRatio)
        }
        
        UIGraphicsBeginImageContextWithOptions(updateSize, false, UIScreen.main.scale)
        self.draw(in: CGRect(origin: .zero, size: updateSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    var pixelSize: CGSize {
        let widthInPixels = self.size.width * self.scale
        let heightInPixels = self.size.height * self.scale
        return CGSize(width: widthInPixels, height: heightInPixels)
    }
}













// MARK: - Int

public extension Int {
    
    /// Number of bytes in one megabyte. Used to set the cost limit of the decoded items NSCache.
    static let OneMegabyte = 1024 * 1024
    
    /// Number of bytes in one gigabyte. Used to set the cost limit of the decoded items NSCache.
    static let OneGigabyte = OneMegabyte * 1000
    
    var megabytes: Int {
        return self * Int.OneMegabyte
    }
    
    var gigabytes: Int {
        return self * Int.OneGigabyte
    }
    
    var sizeInMB: Float {
        return Float(self) / Float(Int.OneMegabyte)
    }
}





// MARK: - Data

internal extension Data {
    
    /// Quick reference for calculating the number of megabytes that a video uses.
    var sizeInMB: Float {
        return self.count.sizeInMB
    }
    
}






// MARK: - URL

internal extension URL {
    
    func withScheme(_ scheme: String) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = scheme
        return components?.url
    }
    
    /// Gets the proper mime type of a URL based on its file extension.
    /// Useful for storing and recreating videos from NSData with the proper mime type.
    func mimeType() -> String {
        let pathExtension = self.pathExtension
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream" // default value
    }
    
    /// Returns a boolean value for if the file at the specified URL is an image
    var containsImage: Bool {
        let mimeType = self.mimeType()
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() else {
            return false
        }
        return UTTypeConformsTo(uti, kUTTypeImage)
    }
    
    /// Returns a boolean value for if the file at the specified URL is an audio file
    var containsAudio: Bool {
        let mimeType = self.mimeType()
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() else {
            return false
        }
        return UTTypeConformsTo(uti, kUTTypeAudio)
    }
    
    /// Returns a boolean value for if the file at the specified URL is a video
    var containsVideo: Bool {
        let mimeType = self.mimeType()
        guard  let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() else {
            return false
        }
        return UTTypeConformsTo(uti, kUTTypeMovie)
    }
}













// MARK: - AVURLAsset

extension AVURLAsset {
    var resoulution: CGSize? {
        guard let track = self.tracks(withMediaType: AVMediaType.video).first else {
            return nil
        }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
    
    static func prepareUsableAsset(withAssetKeys assetKeys: [URLVideoPlayerView.LoadableAssetKeys],
                                   inputURL: URL,
                                   completion: @escaping (AVURLAsset, Error?) -> ()) {
        
        let asset = AVURLAsset(url: inputURL)
        let assetKeyValues = assetKeys.map { $0.rawValue }
        
        var numLoadedKeys: Int = 0
        
        asset.loadValuesAsynchronously(forKeys: assetKeyValues) {
            for key in assetKeys {
                var error: NSError? = nil
                let status = asset.statusOfValue(forKey: key.rawValue, error: &error)
                switch status {
                case .failed:
                    DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error loading asset for url: \(inputURL) failed to load value for key: \(key). Error: \(String(describing: error))")
                    completion(asset, error)
                case .loaded:
                    numLoadedKeys += 1
                    if numLoadedKeys == assetKeys.count {
                        completion(asset, nil)
                    }
                default:
                    DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - asset status: \(status)")
                }
            }
        }
    }
}

extension AVPlayerItem {
    var resolution: CGSize? {
        return (self.asset as? AVURLAsset)?.resoulution
    }
    
    var aspectRatio: Double? {
        guard let width = resolution?.width, let height = resolution?.height else {
           return nil
        }

        return Double(height / width)
    }
}
















// MARK: - FileManager

extension FileManager {
    
    func sizeOfFile(at path: String) -> Int64 {
        do {
            let fileAttributes = try attributesOfItem(atPath: path)
            let fileSizeNumber = fileAttributes[FileAttributeKey.size] as? NSNumber
            let fileSize = fileSizeNumber?.int64Value
            return fileSize ?? 0
        } catch {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - error reading filesize, NSFileManager extension fileSizeAtPath")
            return 0
        }
    }

    func sizeOfFolder(at path: String) -> Int64 {
        var size: Int64 = 0
        do {
            let files = try subpathsOfDirectory(atPath: path)
            for i in 0..<files.count {
                let filePath = path.appending("/"+files[i])
                size += sizeOfFile(at: filePath)
            }
        } catch {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - error reading directory, NSFileManager extension folderSizeAtPath")
        }
        return size
    }
    
    func format(size: Int64) -> String {
        let humanReadableFolderSize = ByteCountFormatter.string(fromByteCount: size, countStyle: ByteCountFormatter.CountStyle.file)
        return humanReadableFolderSize
    }
}
