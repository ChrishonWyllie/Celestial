//
//  FileStorageManager.swift
//  Celestial
//
//  Created by Chrishon Wyllie on 6/22/20.
//

import Foundation
import UIKit

/// Manages directories for downloaded and cached resources
class FileStorageDirectoryManager: NSObject {
    
    // NOTE
    // For hiding access to urls
    
    fileprivate var documentsDirectoryURL: URL {
        return FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory,
                                        in: FileManager.SearchPathDomainMask.userDomainMask).first!
    }
    
    fileprivate var temporaryDirectoryURL: URL {
        
        let pathComponent = "Celestial_Temporary_Directory"
        let destinationURL = documentsDirectoryURL.appendingPathComponent(pathComponent)
        let temporaryDirectoryURL =
            try! FileManager.default.url(for: .itemReplacementDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: destinationURL,
                                        create: true)

        return temporaryDirectoryURL
    }
   
    fileprivate var celestialDirectoryURL: URL {
        let celestialDirectoryName = "Celestial"
        return documentsDirectoryURL.appendingPathComponent(celestialDirectoryName, isDirectory: true)
    }
    fileprivate var videosDirectoryURL: URL {
        let videosDireectoryName = "CachedVideos"
        return celestialDirectoryURL.appendingPathComponent(videosDireectoryName, isDirectory: true)
    }
    fileprivate var imagesDirectoryURL: URL {
        let imagesDirectoryName = "CachedImages"
        return celestialDirectoryURL.appendingPathComponent(imagesDirectoryName, isDirectory: true)
    }
    
    
    override init() {
        super.init()
        createCacheDirectories()
    }
    
    private func createCacheDirectories() {
        createCacheDirectory(at: videosDirectoryURL)
        createCacheDirectory(at: imagesDirectoryURL)
    }
    
    private func createCacheDirectory(at cacheDirectoryURL: URL) {
        do {
            try FileManager.default.createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error creating directory for path: \(cacheDirectoryURL).\n Error: \(error)")
        }
    }
}



/// Manages downloaded and cached resources.
internal protocol FileStorageMangerProtocol {
    var directoryManager: FileStorageDirectoryManager { get }
    
    /**
     Deletes the intermediate temporary file that was created after the `DownloadTaskManager` completes a request

    - Parameters:
       - intermediateTemporaryFileLocation: The temporary url of the resource that was recently downloaded
    - Returns:
       - Boolean value of whether the file was successfully deleted
    */
    @discardableResult func deleteFileAt(intermediateTemporaryFileLocation location: URL) -> Bool
    
    /**
     Clears the cache of the specified file type

    - Parameters:
       - style: The directory to be cleared. (Images, Videos, all)
    */
    func clearCache(_ style: FileStorageManager.CacheClearingStyle)
    
    /**
     Moves the temporary file created from a download task to an intermediate location

    - Parameters:
       - originalTemporaryURL: The url of the downloaded resource that is generated as a result of a `URLSessionDownloadTask`
    - Returns:
       The intermediate temporary url of the downloaded resource. May throw error if moving the file fails
    */
    func moveToIntermediateTemporaryURL(originalTemporaryURL: URL) throws -> URL
    
    /**
     Resizes the video with a given resolution and caches it

    - Parameters:
       - sourceURL: The url of the resource that has been requested
       - resolution: The resolution to downsize the video to
       - intermediateTemporaryFileURL: The intermediate file url that the downloaded resource has been moved to after the `URLSessionDownloadTask` has completed
     
    - Returns:
       - A url of the newly resized and cached resource
    */
    func cachedAndResizedVideo(sourceURL: URL, resolution: CGSize, intermediateTemporaryFileURL: URL) -> URL?
    
    /**
     Resizes the image with a given resolution and caches it

    - Parameters:
       - sourceURL: The url of the resource that has been requested
       - size: The iOS point size to downsize the image to
       - intermediateTemporaryFileURL: The intermediate file url that the downloaded resource has been moved to after the `URLSessionDownloadTask` has completed
     
    - Returns:
       - A image of the newly resized and cached resource
    */
    func cachedAndResizedImage(sourceURL: URL, size: CGSize, intermediateTemporaryFileURL: URL) -> UIImage?
    
    /**
     Returns a url for the cached resource

    - Parameters:
       - sourceURL: The url of the resource that has been requested
     
    - Returns:
       - A url of the cached resource
    */
    func getCachedVideoURL(for sourceURL: URL) -> URL?
    
    /**
     Returns a url for the cached resource

    - Parameters:
       - sourceURL: The url of the resource that has been requested
       - size: The iOS point size of the image. Used to cache multiple sizes of the same image in order to maintain quality when displaying in different UIImageView sizes
     
    - Returns:
       - A url of the cached resource
    */
    func getCachedImageURL(for sourceURL: URL, size: CGSize) -> URL?
    
    /**
     Returns a boolean value of whether the video exists

    - Parameters:
       - sourceURL: The url of the resource that has been requested
     
    - Returns:
       - A boolean value of whether the resource has been cached and exists for use
    */
    func videoExists(for sourceURL: URL) -> Bool
    
    /**
     Returns a boolean value of whether the image exists

    - Parameters:
       - sourceURL: The url of the resource that has been requested
     
    - Returns:
       - A boolean value of whether the resource has been cached and exists for use
    */
    func imageExists(for sourceURL: URL) -> Bool
}


class FileStorageManager: NSObject, FileStorageMangerProtocol {
    
    // MARK: - Variables
    
    public static let shared = FileStorageManager()
    
    let directoryManager = FileStorageDirectoryManager()
    
    enum CacheClearingStyle {
        case videos
        case images
        case all
    }
    
    
    
    
    // MARK: - Initializers
    
    private override init() {
        super.init()
    }
    
    
    
    
    
    
    
    
    
    
    // MARK: - Functions
    
    @discardableResult internal func deleteFileAt(intermediateTemporaryFileLocation location: URL) -> Bool {
        return deleteFile(forCompleteFilePath: location)
    }
    
    @discardableResult private func deleteFile(forCompleteFilePath filePath: URL) -> Bool {
        do {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Attempting to delete file for path: \(filePath)")
            try FileManager.default.removeItem(at: filePath)
            return true
        } catch let error {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error deleting file for path: \(filePath).\n Error: \(error)")
            return false
        }
    }
    
    internal func clearCache(_ style: CacheClearingStyle) {
        switch style {
        case .videos: deleteItemsInDirectory(for: directoryManager.videosDirectoryURL)
        case .images: deleteItemsInDirectory(for: directoryManager.imagesDirectoryURL)
        default:      deleteItemsInDirectory(for: directoryManager.celestialDirectoryURL)
        }
    }
    
    private func deleteItemsInDirectory(for directoryURL: URL) {
        do {
            getInfoForDirectory(at: directoryURL)
            
            guard let directoryContents = try? FileManager.default.contentsOfDirectory(atPath: directoryURL.path) else {
                return
            }
            
            for path in directoryContents {
                let filePath = directoryURL.appendingPathComponent(path)
                try FileManager.default.removeItem(at: filePath)
            }
            
        } catch let error {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error deleting directory at path: \(directoryURL.path).\n Error: \(error)")
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    internal func moveToIntermediateTemporaryURL(originalTemporaryURL: URL) throws -> URL {
        let temporaryFilename = ProcessInfo().globallyUniqueString

        let intermediateTemporaryFileURL =
            directoryManager.temporaryDirectoryURL.appendingPathComponent(temporaryFilename)
        
        try FileManager.default.copyItem(at: originalTemporaryURL, to: intermediateTemporaryFileURL)
        return intermediateTemporaryFileURL
    }
    
    internal func cachedAndResizedVideo(sourceURL: URL, resolution: CGSize, intermediateTemporaryFileURL: URL) -> URL? {
        return nil
    }
    
    internal func cachedAndResizedImage(sourceURL: URL, size: CGSize, intermediateTemporaryFileURL: URL) -> UIImage? {
        
        var cachedAndResizedImage: UIImage?
        
        let sizeFormattedURL = constructFormattedURL(from: sourceURL, expectedDirectoryURL: directoryManager.imagesDirectoryURL, size: size)
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - new size formatted url: \(sizeFormattedURL.path)")
        
        do {
            // Create Data from url
            let imageDataFromTemporaryFileURL: Data = try Data(contentsOf: intermediateTemporaryFileURL)
            
            // Re-create the originally downloaded image
            guard let imageFromTemporaryFileURL: UIImage = UIImage(data: imageDataFromTemporaryFileURL) else {
                return nil
            }
            
            // Downsize this image
            guard let resizedImage: UIImage = imageFromTemporaryFileURL.resize(size: size) else {
                return nil
            }
            
            cachedAndResizedImage = resizedImage
            
            // Convert downsized image back to Data
            guard let resizedImageData: Data = resizedImage.pngData() else {
                return nil
            }
            
            // Finally, write this downsized image Data to the newly created permanent url
            try resizedImageData.write(to: sizeFormattedURL)
            
        } catch let error {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error caching and downsizing the downloaded image for source url: \(sourceURL). Error: \(error)")
        }
        
        // Finally delete the local intermediate file
        deleteFileAt(intermediateTemporaryFileLocation: intermediateTemporaryFileURL)
        
        return cachedAndResizedImage
    }
    
    internal func getCachedVideoURL(for sourceURL: URL) -> URL? {
//        guard let track = AVURLAsset(url: sourceURL).tracks(withMediaType: AVMediaTypeVideo).first else { return nil }
//        let size = track.naturalSize.applying(track.preferredTransform)
//        return CGSize(width: fabs(size.width), height: fabs(size.height))
        let size = CGSize.zero
        
        let downloadedFileURL = constructFormattedURL(from: sourceURL, expectedDirectoryURL: directoryManager.videosDirectoryURL, size: size)

        if FileManager.default.fileExists(atPath: downloadedFileURL.path) {
            return downloadedFileURL
        } else {
            return nil
        }
    }
    
    internal func getCachedImageURL(for sourceURL: URL, size: CGSize) -> URL? {
        let downloadedFileURL = constructFormattedURL(from: sourceURL, expectedDirectoryURL: directoryManager.imagesDirectoryURL, size: size)
        
        if FileManager.default.fileExists(atPath: downloadedFileURL.path) {
            return downloadedFileURL
        } else {
            return nil
        }
    }
    
    
    
    internal func videoExists(for sourceURL: URL) -> Bool {
        return downloadedFileExists(for: sourceURL, inDirectory: directoryManager.videosDirectoryURL)
    }
    
    internal func imageExists(for sourceURL: URL) -> Bool {
        return downloadedFileExists(for: sourceURL, inDirectory: directoryManager.imagesDirectoryURL)
    }
    
    
    
    private func downloadedFileExists(for sourceURL: URL, inDirectory directoryURL: URL) -> Bool {
        let actualFileName = sourceURL.lastPathComponent
        
        guard let directoryContents = try? FileManager.default.contentsOfDirectory(atPath: directoryURL.path) else {
            return false
        }
        
        for storedFileName in directoryContents {
            if storedFileName.hasPrefix(actualFileName) {
                return true
            }
        }
        
        return false
    }
    
    private func constructFormattedURL(from sourceURL: URL, expectedDirectoryURL: URL, size: CGSize) -> URL {
        // size: CGSize(width: 327.0, height: 246.0)
        // image name 1: URL: https://picsum.photos/id/0/5616/3744 -> becomes -> 3744-size-327.0-246.0 (no extension)
        // image name 2: URL: https://server/url/to/your/image.png -> becomes -> image-size-327.0-246.0.png
        let sizePathComponent: String = "-size-\(size.width)-\(size.height)"
        let actualFileName = sourceURL.lastPathComponent
        
        var formattedFileName = actualFileName + sizePathComponent
        
        if sourceURL.pathExtension.count > 0 {
            formattedFileName += ".\(sourceURL.pathExtension)"
        }
        let sizeFormattedURL = expectedDirectoryURL.appendingPathComponent(formattedFileName)
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Constructing formatted URL: \(sizeFormattedURL)")
        return sizeFormattedURL
    }
    
    private func getInfoForDirectory(at directoryURL: URL) {
        guard let directoryContents = try? FileManager.default.contentsOfDirectory(atPath: directoryURL.path) else {
            return
        }
        
        let folderSize = FileManager.default.sizeOfFolder(at: directoryURL.path)
        let formattedFolderSize = FileManager.default.format(size: folderSize)
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Number of items in directory: \(String(describing: directoryContents.count)). Folder size: \(formattedFolderSize)")
        
        do {
            for fileName in directoryContents {
                let fileURL = directoryURL.appendingPathComponent(fileName)

                let fileAttribute = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                let fileSize = fileAttribute[FileAttributeKey.size] as? Int64 ?? 0
                let formattedFileSize = FileManager.default.format(size: fileSize)
                let fileType = fileAttribute[FileAttributeKey.type] as? String
                let filecreationDate = fileAttribute[FileAttributeKey.creationDate] as? Date
                let fileExtension = fileURL.pathExtension

                DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - file Name: \(fileName), Size: \(formattedFileSize), Type: \(String(describing: fileType)), Date: \(String(describing: filecreationDate)), Extension: \(fileExtension)")
            }
        } catch let error {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error getting attributes of item in directory: \(directoryURL.path). Error: \(error)")
        }
        
    }
}
