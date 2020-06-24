//
//  FileStorageManager.swift
//  Celestial
//
//  Created by Chrishon Wyllie on 6/22/20.
//

import Foundation
import UIKit

class FileStorageManager: NSObject {
    
    // MARK: - Variables
    
    public static let shared = FileStorageManager()
    
    var documentsDirectoryURL: URL {
        return FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory,
                                        in: FileManager.SearchPathDomainMask.userDomainMask).first!
    }
    
    var temporaryDirectoryURL: URL {
        
        let pathComponent = "Celestial_Temporary_Directory"
        let destinationURL = documentsDirectoryURL.appendingPathComponent(pathComponent)
        let temporaryDirectoryURL =
            try! FileManager.default.url(for: .itemReplacementDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: destinationURL,
                                        create: true)

        return temporaryDirectoryURL
    }
    var celestialDirectoryURL: URL {
        let celestialDirectoryPathName = "Celestial"
        return documentsDirectoryURL.appendingPathComponent(celestialDirectoryPathName, isDirectory: true)
    }
    var videosDirectoryURL: URL {
        let videosDireectoryPathName = "CachedVideos"
        return celestialDirectoryURL.appendingPathComponent(videosDireectoryPathName, isDirectory: true)
    }
    var imagesDirectoryURL: URL {
        let imagesDirectoryPathName = "CachedImages"
        return celestialDirectoryURL.appendingPathComponent(imagesDirectoryPathName, isDirectory: true)
    }
    
    
    
    
    
    
    // MARK: - Initializers
    
    private override init() {
        super.init()
        createCacheDirectories()
    }
    
    
    
    
    
    
    
    
    
    
    // MARK: - Functions
    
    private func createCacheDirectories() {
        createCacheDirectory(at: videosDirectoryURL)
        createCacheDirectory(at: imagesDirectoryURL)
//        createCacheDirectory(at: temporaryDirectoryURL)
    }
    
    private func createCacheDirectory(at cacheDirectoryPath: URL) {
        do {
            try FileManager.default.createDirectory(at: cacheDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error creating directory for path: \(cacheDirectoryPath).\n Error: \(error)")
        }
    }
    
    func replaceFileAt(temporaryFileURL: URL, withDestinationURL destinationURL: URL) throws {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: destinationURL)
        try fileManager.copyItem(at: temporaryFileURL, to: destinationURL)
    }
    
    func localFilePath(for url: URL) -> URL {
        switch url.fileType {
        case .video: return videosDirectoryURL.appendingPathComponent(url.lastPathComponent)
        case .image: return imagesDirectoryURL.appendingPathComponent(url.lastPathComponent)
        case .audio: fatalError("Not implemented")
        }
    }
    
    func downloadedFile(for sourceURL: URL) -> URL? {
        let downloadedFileURL = localFilePath(for: sourceURL)
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - searching for downloaded file with local url: \(downloadedFileURL)")
        if FileManager.default.fileExists(atPath: downloadedFileURL.path) {
            return downloadedFileURL
        } else {
            return nil
        }
    }
    
    @discardableResult func deleteFile(forOriginalSourceURL sourceURL: URL) -> Bool {
        guard let filePath = downloadedFile(for: sourceURL) else {
            return false
        }
        return deleteFile(forCompleteFilePath: filePath)
    }
    
    @discardableResult func deleteFile(forCompleteFilePath filePath: URL) -> Bool {
        do {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Attempting to delete file for path: \(filePath)")
            try FileManager.default.removeItem(at: filePath)
            return true
        } catch let error {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error deleting file for path: \(filePath).\n Error: \(error)")
            return false
        }
    }
    
    func deleteAllFiles(ofType fileType: MediaFileType) {
        switch fileType {
        case .video: deleteDirectory(for: videosDirectoryURL)
        case .image: deleteDirectory(for: imagesDirectoryURL)
        default: fatalError("Not implemented")
        }
    }
    
    func test() {
        getInfoForDirectory(at: videosDirectoryURL)
        getInfoForDirectory(at: imagesDirectoryURL)
    }
    
    enum CacheClearingStyle {
        case videos
        case images
        case all
    }
    
    func clearCache(_ style: CacheClearingStyle) {
        switch style {
        case .videos: deleteDirectory(for: videosDirectoryURL)
        case .images: deleteDirectory(for: imagesDirectoryURL)
        default:
            deleteDirectory(for: celestialDirectoryURL)
        }
    }
    
    private func deleteDirectory(for directoryPath: URL) {
        do {
            getInfoForDirectory(at: directoryPath)
            
            guard let directoryContents = try? FileManager.default.contentsOfDirectory(atPath: directoryPath.path) else {
                return
            }
            
            for path in directoryContents {
                let filePath = directoryPath.appendingPathComponent(path)
                try FileManager.default.removeItem(at: filePath)
            }
            
//            try FileManager.default.removeItem(atPath: directoryPath.path)
        } catch let error {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error deleting directory at path: \(directoryPath.path).\n Error: \(error)")
        }
    }
    
    private func getInfoForDirectory(at directoryPath: URL) {
        guard let directoryContents = try? FileManager.default.contentsOfDirectory(atPath: directoryPath.path) else {
            return
        }
        
        let folderSize = FileManager.default.folderSizeAtPath(path: directoryPath.path)
        let formattedFolderSize = FileManager.default.format(size: folderSize)
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Number of items in directory: \(String(describing: directoryContents.count)). Folder size: \(formattedFolderSize)")
        
        do {
            for fileName in directoryContents {
                let fileURL = directoryPath.appendingPathComponent(fileName)

                let fileAttribute = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                let fileSize = fileAttribute[FileAttributeKey.size] as! Int64
                let formattedFileSize = FileManager.default.format(size: fileSize)
                let fileType = fileAttribute[FileAttributeKey.type] as! String
                let filecreationDate = fileAttribute[FileAttributeKey.creationDate] as! Date
                let fileExtension = fileURL.pathExtension;

                DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - file Name: \(fileName), Size: \(formattedFileSize), Type: \(fileType), Date: \(filecreationDate), Extension: \(fileExtension)")
            }
        } catch let error {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error getting attributes of item in directory: \(directoryPath.path). Error: \(error)")
        }
        
    }
    
    
    
    
    
    
    
    
    
    internal func moveToIntermediateTemporaryURL(originalTemporaryURL: URL) throws -> URL {
        let temporaryFilename = ProcessInfo().globallyUniqueString

        let intermediateTemporaryFileURL =
            temporaryDirectoryURL.appendingPathComponent(temporaryFilename)
        
        try FileManager.default.copyItem(at: originalTemporaryURL, to: intermediateTemporaryFileURL)
        return intermediateTemporaryFileURL
    }
    
    internal func cacheAndResizeImage(sourceURL: URL, size: CGSize, intermediateTemporaryFileURL: URL) -> UIImage? {
        
        var cachedAndResizedImage: UIImage?
        
        let sizeFormattedURL = constructFormattedURL(from: sourceURL, expectedDirectoryURL: imagesDirectoryURL, size: size)
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - new size formatted url: \(sizeFormattedURL.path)")
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - new size formatted url: \(sizeFormattedURL.absoluteString)")
        
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
//        let imageData = try! Data(contentsOf: intermediateTemporaryFileURL)
//        let downloadedImage = UIImage(data: imageData)!
//        let resizedImage = downloadedImage.resize(size: size)!
//        let resizedImageData = resizedImage.pngData()!
//        try! resizedImageData.write(to: sizeFormattedURL, options: Data.WritingOptions.atomic)
        
//        let downloadedFileExistsKey: String = imagesDirectoryURL.appendingPathComponent(sourceURL.absoluteString).absoluteString
//        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Storing file exists for user defaults key: \(downloadedFileExistsKey)")
//        UserDefaults.standard.setValue(true, forKey: downloadedFileExistsKey)
        
        // Finally delete the local intermediate file
        deleteFile(forCompleteFilePath: intermediateTemporaryFileURL)
        
        return cachedAndResizedImage
    }
    
    internal func getCachedImageURL(for sourceURL: URL, size: CGSize) -> URL? {
        let downloadedFileURL = constructFormattedURL(from: sourceURL, expectedDirectoryURL: imagesDirectoryURL, size: size)
        
        if FileManager.default.fileExists(atPath: downloadedFileURL.path) {
            return downloadedFileURL
        } else {
            return nil
        }
    }
    
    internal func imageExists(for sourceURL: URL) -> Bool {
        
        let actualFileName = sourceURL.lastPathComponent
        
        guard let directoryContents = try? FileManager.default.contentsOfDirectory(atPath: imagesDirectoryURL.path) else {
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
    
}
























extension FileManager {
    
    func fileSizeAtPath(path: String) -> Int64 {
        do {
            let fileAttributes = try attributesOfItem(atPath: path)
            let fileSizeNumber = fileAttributes[FileAttributeKey.size] as? NSNumber
            let fileSize = fileSizeNumber?.int64Value
            return fileSize!
        } catch {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - error reading filesize, NSFileManager extension fileSizeAtPath")
            return 0
        }
    }

    func folderSizeAtPath(path: String) -> Int64 {
        var size : Int64 = 0
        do {
            let files = try subpathsOfDirectory(atPath: path)
            for i in 0 ..< files.count {
                size += fileSizeAtPath(path: path.appending("/"+files[i]))
            }
        } catch {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - error reading directory, NSFileManager extension folderSizeAtPath")
        }
        return size
    }
    
    func format(size: Int64) -> String {
        let folderSizeStr = ByteCountFormatter.string(fromByteCount: size, countStyle: ByteCountFormatter.CountStyle.file)
        return folderSizeStr
    }
}
