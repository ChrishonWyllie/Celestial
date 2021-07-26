//
//  Extensions.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import UIKit
import MobileCoreServices
import AVFoundation

// MARK: - AVAsset

extension AVAsset {
    
    func generateThumbnailImage(at time: CMTime, completion: @escaping (_ image: UIImage?) -> ()) {
        let assetGenerator = AVAssetImageGenerator(asset: self)
        assetGenerator.appliesPreferredTrackTransform = true
    
        let timeFrameValue = NSValue(time: time)
        
        assetGenerator.generateCGImagesAsynchronously(forTimes: [timeFrameValue]) { (timeOne, cgImage, timeTwo, result, error) in
            if let error = error {
                DebugLogger.shared.addDebugMessage("\(String(describing: self)) - Error generating thumbnail image from AVAsset. Error: \(error.localizedDescription)")
            }
            
            if let cgImage = cgImage {
                completion(UIImage(cgImage: cgImage))
            }
        }
    }
}

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
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() else {
            return false
        }
        return UTTypeConformsTo(uti, kUTTypeMovie)
    }
    
    func localUniqueFileName(concatenateFileExtension: Bool? = false) -> String {
        let fileExtension = self.pathExtension
        var uniqueFileName: String = self.lastPathComponent.convertURLToUniqueFileName()
        if concatenateFileExtension == true {
            uniqueFileName += "-\(fileExtension)"
        }
        return uniqueFileName
    }
}

extension String {
    func convertURLToUniqueFileName() -> String {
        guard let _ = URL(string: self) else {
            fatalError("\(self) is not a valid URL")
        }
        return self.md5
    }
    
    var isValidURL: Bool {
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
                // it is a link, if the match covers the whole string
                return match.range.length == self.utf16.count
            } else {
                return false
            }
        } catch let error {
            DebugLogger.shared.addDebugMessage("\(String(describing: self)) - Error determining if String is a valid URL. Error: \(error.localizedDescription)")
            return false
        }
    }
}




// MARK: - SandboxPath

extension String {
    
    public var md5DotMp4: String {
        return self.kf.md5 + ".mp4"
    }
    public var md5: String {
        return self.kf.md5
    }
    
    public var cacheDir: String {
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last!
        return (path as NSString).appendingPathComponent((self as NSString).lastPathComponent)
    }
    
    public var docDir: String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
        return (path as NSString).appendingPathComponent((self as NSString).lastPathComponent)
    }
    public var tmpDir: String {
        
        let path = NSTemporaryDirectory() as NSString
        return path.appendingPathComponent((self as NSString).lastPathComponent)
        
    }
    
}


import Foundation

public struct StringProxy {
    fileprivate let base: String
    init(proxy: String) {
        base = proxy
    }
}

extension String {
    public typealias CompatibleType = StringProxy
    public var kf: CompatibleType {
        return StringProxy(proxy: self)
    }
    
}

extension StringProxy {
    var md5: String {
        if let data = base.data(using: .utf8, allowLossyConversion: true) {
            
            let message = data.withUnsafeBytes { bytes -> [UInt8] in
                return Array(UnsafeBufferPointer(start: bytes, count: data.count))
            }
            
            let MD5Calculator = MD5(message)
            let MD5Data = MD5Calculator.calculate()
            
            var MD5String = String()
            for c in MD5Data {
                MD5String += String(format: "%02x", c)
            }
            return MD5String
            
        } else {
            return base
        }
    }
}

/** array of bytes, little-endian representation */
func arrayOfBytes<T>(_ value: T, length: Int? = nil) -> [UInt8] {
    let totalBytes = length ?? (MemoryLayout<T>.size * 8)
    
    let valuePointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    valuePointer.pointee = value
    
    let bytes = valuePointer.withMemoryRebound(to: UInt8.self, capacity: totalBytes) { (bytesPointer) -> [UInt8] in
        var bytes = [UInt8](repeating: 0, count: totalBytes)
        for j in 0..<min(MemoryLayout<T>.size, totalBytes) {
            bytes[totalBytes - 1 - j] = (bytesPointer + j).pointee
        }
        return bytes
    }
    
    valuePointer.deinitialize(count: 1)
    valuePointer.deallocate()
    
    return bytes
}

extension Int {
    /** Array of bytes with optional padding (little-endian) */
    func bytes(_ totalBytes: Int = MemoryLayout<Int>.size) -> [UInt8] {
        return arrayOfBytes(self, length: totalBytes)
    }
    
}

extension NSMutableData {
    
    /** Convenient way to append bytes */
    func appendBytes(_ arrayOfBytes: [UInt8]) {
        append(arrayOfBytes, length: arrayOfBytes.count)
    }
    
}

protocol HashProtocol {
    var message: [UInt8] { get }
    
    /** Common part for hash calculation. Prepare header data. */
    func prepare(_ len: Int) -> [UInt8]
}

extension HashProtocol {
    
    func prepare(_ len: Int) -> [UInt8] {
        var tmpMessage = message
        
        // Step 1. Append Padding Bits
        tmpMessage.append(0x80) // append one bit (UInt8 with one bit) to message
        
        // append "0" bit until message length in bits ≡ 448 (mod 512)
        var msgLength = tmpMessage.count
        var counter = 0
        
        while msgLength % len != (len - 8) {
            counter += 1
            msgLength += 1
        }
        
        tmpMessage += [UInt8](repeating: 0, count: counter)
        return tmpMessage
    }
}

func toUInt32Array(_ slice: ArraySlice<UInt8>) -> [UInt32] {
    var result = [UInt32]()
    result.reserveCapacity(16)
    
    for idx in stride(from: slice.startIndex, to: slice.endIndex, by: MemoryLayout<UInt32>.size) {
        let d0 = UInt32(slice[idx.advanced(by: 3)]) << 24
        let d1 = UInt32(slice[idx.advanced(by: 2)]) << 16
        let d2 = UInt32(slice[idx.advanced(by: 1)]) << 8
        let d3 = UInt32(slice[idx])
        let val: UInt32 = d0 | d1 | d2 | d3
        
        result.append(val)
    }
    return result
}

struct BytesIterator: IteratorProtocol {
    
    let chunkSize: Int
    let data: [UInt8]
    
    init(chunkSize: Int, data: [UInt8]) {
        self.chunkSize = chunkSize
        self.data = data
    }
    
    var offset = 0
    
    mutating func next() -> ArraySlice<UInt8>? {
        let end = min(chunkSize, data.count - offset)
        let result = data[offset..<offset + end]
        offset += result.count
        return result.count > 0 ? result : nil
    }
}

struct BytesSequence: Sequence {
    let chunkSize: Int
    let data: [UInt8]
    
    func makeIterator() -> BytesIterator {
        return BytesIterator(chunkSize: chunkSize, data: data)
    }
}

func rotateLeft(_ value: UInt32, bits: UInt32) -> UInt32 {
    return ((value << bits) & 0xFFFFFFFF) | (value >> (32 - bits))
}

class MD5: HashProtocol {
    
    static let size = 16 // 128 / 8
    let message: [UInt8]
    
    init (_ message: [UInt8]) {
        self.message = message
    }
    
    /** specifies the per-round shift amounts */
    private let shifts: [UInt32] = [7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
                                    5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
                                    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
                                    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21]
    
    /** binary integer part of the sines of integers (Radians) */
    private let sines: [UInt32] = [0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
                                   0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
                                   0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
                                   0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
                                   0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
                                   0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
                                   0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
                                   0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
                                   0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
                                   0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
                                   0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x4881d05,
                                   0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
                                   0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
                                   0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
                                   0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
                                   0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391]
    
    private let hashes: [UInt32] = [0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476]
    
    func calculate() -> [UInt8] {
        var tmpMessage = prepare(64)
        tmpMessage.reserveCapacity(tmpMessage.count + 4)
        
        // hash values
        var hh = hashes
        
        // Step 2. Append Length a 64-bit representation of lengthInBits
        let lengthInBits = (message.count * 8)
        let lengthBytes = lengthInBits.bytes(64 / 8)
        tmpMessage += lengthBytes.reversed()
        
        // Process the message in successive 512-bit chunks:
        let chunkSizeBytes = 512 / 8 // 64
        
        for chunk in BytesSequence(chunkSize: chunkSizeBytes, data: tmpMessage) {
            // break chunk into sixteen 32-bit words M[j], 0 ≤ j ≤ 15
            var M = toUInt32Array(chunk)
            assert(M.count == 16, "Invalid array")
            
            // Initialize hash value for this chunk:
            var A: UInt32 = hh[0]
            var B: UInt32 = hh[1]
            var C: UInt32 = hh[2]
            var D: UInt32 = hh[3]
            
            var dTemp: UInt32 = 0
            
            // Main loop
            for j in 0 ..< sines.count {
                var g = 0
                var F: UInt32 = 0
                
                switch j {
                case 0...15:
                    F = (B & C) | ((~B) & D)
                    g = j
                    break
                case 16...31:
                    F = (D & B) | (~D & C)
                    g = (5 * j + 1) % 16
                    break
                case 32...47:
                    F = B ^ C ^ D
                    g = (3 * j + 5) % 16
                    break
                case 48...63:
                    F = C ^ (B | (~D))
                    g = (7 * j) % 16
                    break
                default:
                    break
                }
                dTemp = D
                D = C
                C = B
                B = B &+ rotateLeft((A &+ F &+ sines[j] &+ M[g]), bits: shifts[j])
                A = dTemp
            }
            
            hh[0] = hh[0] &+ A
            hh[1] = hh[1] &+ B
            hh[2] = hh[2] &+ C
            hh[3] = hh[3] &+ D
        }
        
        var result = [UInt8]()
        result.reserveCapacity(hh.count / 4)
        
        hh.forEach {
            let itemLE = $0.littleEndian
            let r1 = UInt8(itemLE & 0xff)
            let r2 = UInt8((itemLE >> 8) & 0xff)
            let r3 = UInt8((itemLE >> 16) & 0xff)
            let r4 = UInt8((itemLE >> 24) & 0xff)
            result += [r1, r2, r3, r4]
        }
        return result
    }
}

extension NSString {
    
    var md5: NSString {
        
        return ((self as String).md5 as NSString)
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











// MARK: - NSError

extension NSError {
    static func createError(withString localizedString: String, description: String, comment: String?, domain: String, code: Int?) -> NSError {
        let userInfo: [String : Any] = [NSLocalizedDescriptionKey: NSLocalizedString(localizedString, value: description, comment: comment ?? "")]
        return NSError(domain: domain, code: code ?? 1, userInfo: userInfo)
    }
    
}
