//
//  FileStorageManager.swift
//  Celestial
//
//  Created by Chrishon Wyllie on 6/22/20.
//

import Foundation
import UIKit
import AVFoundation

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
     Deletes the video that was created from the source URL. Will delete all copies of the video, including ones at different resolutions

    - Parameters:
       - sourceURL: The source URL of the video
    - Returns:
       Boolean value of whether the file was successfully deleted
    */
    @discardableResult func deleteCachedVideo(using sourceURL: URL) -> Bool
    
    
    
    /**
     Deletes the image that was created from the source URL. Will delete all copies of the image, including ones at different iOS point sizes

    - Parameters:
       - sourceURL: The source URL of the video
    - Returns:
       Boolean value of whether the file was successfully deleted
    */
    @discardableResult func deleteCachedImage(using sourceURL: URL) -> Bool
    
    /**
     Clears the cache of the specified file type

    - Parameters:
       - fileType: Determines which directory will be cleared. (Images, Videos, all)
    */
    func clearCache(fileType: Celestial.ResourceFileType)
    
    /**
     Moves the temporary file created from a download task to an intermediate location

    - Parameters:
       - originalTemporaryURL: The url of the downloaded resource that is generated as a result of a `URLSessionDownloadTask`
       - sourceURL: The original url of the requested resource (i.e., the URL that points to the resource on your server, etc.)
     
    - Returns:
       The intermediate temporary url of the downloaded resource. May throw error if moving the file fails
    */
    func moveToIntermediateTemporaryURL(originalTemporaryURL: URL, sourceURL: URL) throws -> URL
    
    /**
     Resizes the video with a given resolution and caches it

    - Parameters:
       - sourceURL: The url of the resource that has been requested
       - resolution: The resolution to downsize the video to
       - intermediateTemporaryFileURL: The intermediate file url that the downloaded resource has been moved to after the `URLSessionDownloadTask` has completed
       - completion: Executes completion block with a URL pointing to a compressed video
    
    */
    func cachedAndResizedVideo(sourceURL: URL, resolution: CGSize, intermediateTemporaryFileURL: URL, completion: @escaping (_ compressedVideoURL: URL?) -> ())
    
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
       - resolution: The desired resolution of the video. Used to cache multiple sizes of the same video in order to maintain quality when displaying in different AVPlayerLayer sizes
     
    - Returns:
       - A url of the cached resource
    */
    func getCachedVideoURL(for sourceURL: URL, resolution: CGSize) -> URL?
    
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
    
    /// Splits a url into different parts for use later
    private struct SourceURLDecomposition {
        let actualFileName: String
        let fileExtension: String
    }
    
    
    
    // MARK: - Initializers
    
    private override init() {
        super.init()
    }
    
    
    
    
    
    
    
    
    
    
    // MARK: - Functions
    
    @discardableResult internal func deleteFileAt(intermediateTemporaryFileLocation location: URL) -> Bool {
        return deleteFile(forCompleteFilePath: location)
    }
    
    @discardableResult internal func deleteCachedVideo(using sourceURL: URL) -> Bool {
        return deleteFile(inDirectory: directoryManager.videosDirectoryURL, matchingSourceURL: sourceURL)
    }
    
    @discardableResult internal func deleteCachedImage(using sourceURL: URL) -> Bool {
        return deleteFile(inDirectory: directoryManager.imagesDirectoryURL, matchingSourceURL: sourceURL)
    }
    
    private func deleteFile(inDirectory directoryURL: URL, matchingSourceURL sourceURL: URL) -> Bool {
        let actualFileName = sourceURL.lastPathComponent
        
        guard let directoryContents = try? FileManager.default.contentsOfDirectory(atPath: directoryURL.path) else {
            return false
        }
        
        let filesMatchingSourceURL = directoryContents.filter { (file) -> Bool in
            return file.hasPrefix(actualFileName)
        }
        
        if filesMatchingSourceURL.count > 0 {
            for matchingFileName in filesMatchingSourceURL {
                do {
                    let fileToDelete = directoryURL.appendingPathComponent(matchingFileName)
                    try FileManager.default.removeItem(at: fileToDelete)
                } catch let error {
                    DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error deleting file from director. Error: \(error)")
                }
            }
            
            return true
        } else {
            return false
        }
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
    
    internal func clearCache(fileType: Celestial.ResourceFileType) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let strongSelf = self else { return }
            switch fileType {
            case .video: strongSelf.deleteItemsInDirectory(for: strongSelf.directoryManager.videosDirectoryURL)
            case .image: strongSelf.deleteItemsInDirectory(for: strongSelf.directoryManager.imagesDirectoryURL)
            default:      strongSelf.deleteItemsInDirectory(for: strongSelf.directoryManager.celestialDirectoryURL)
            }
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
    
    
    
    
    
    
    
    
    
    
    
    internal func moveToIntermediateTemporaryURL(originalTemporaryURL: URL, sourceURL: URL) throws -> URL {
        let intermediateTemporaryFileURL = createTemporaryFileURL(from: sourceURL)
        try FileManager.default.copyItem(at: originalTemporaryURL, to: intermediateTemporaryFileURL)
        return intermediateTemporaryFileURL
    }
    
    internal func createTemporaryFileURL(from sourceURL: URL) -> URL {
        let sourceURLDecomposition = decomposed(sourceURL: sourceURL)
        let actualFileName = sourceURLDecomposition.actualFileName
        let fileExtension = sourceURLDecomposition.fileExtension
        let pathComponent = actualFileName + ".\(fileExtension)"
        let intermediateTemporaryFileURL =
            directoryManager.temporaryDirectoryURL.appendingPathComponent(pathComponent)
        
        return intermediateTemporaryFileURL
    }
    
    internal func cachedAndResizedVideo(sourceURL: URL,
                                        resolution: CGSize,
                                        intermediateTemporaryFileURL: URL,
                                        completion: @escaping (_ compressedVideoURL: URL?) -> ()) {

        let sizeFormattedURL = constructFormattedURL(from: sourceURL, expectedDirectoryURL: directoryManager.videosDirectoryURL, size: resolution)
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - new size formatted url: \(sizeFormattedURL.path)")
        
        decreaseVideoQuality(sourceURL: sourceURL, inputURL: intermediateTemporaryFileURL, outputURL: sizeFormattedURL) { (sizeFormattedCompressedURL) in
            
            // Finally delete the local intermediate file
            self.deleteFileAt(intermediateTemporaryFileLocation: intermediateTemporaryFileURL)
                        
            completion(sizeFormattedCompressedURL)
        }
    }
    
    internal func decreaseVideoQuality(sourceURL: URL, inputURL: URL, outputURL: URL, completion: @escaping (URL?) -> ()) {
        
        let uncompressedVideoData = try! Data(contentsOf: inputURL)
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - File size before compression: \(uncompressedVideoData.sizeInMB)")
        
        
        asyncSetupExportableAsset(with: inputURL) { [weak self] (exportableAsset) in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.exportLowerQualityVideo(fromAsset: exportableAsset, to: outputURL) { (exportSession) in
                guard let exportSession = exportSession else {
                    return
                }
                
                switch exportSession.status {
                case .exporting:
                    DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Exporting video for url: \(outputURL). Progress: \(exportSession.progress)")
                    
                case .completed:
                    if let compressedVideoData = try? Data(contentsOf: outputURL) {
                        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - File size after compression: \(compressedVideoData.sizeInMB)")
                    } else {
                        let fileExists = strongSelf.videoExists(for: sourceURL)
                        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Finished compressing, but no such file exists at output url: \(outputURL). File exists: \(fileExists)")
                    }
                    
                    completion(outputURL)
                case .failed:
                    DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - failed to export url: \(outputURL). Error: \(String(describing: exportSession.error))")
                case .cancelled:
                    DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - export for url: \(outputURL) cancelled")
                case .unknown: break
                case .waiting: break
                @unknown default:
                    fatalError()
                }
            }
        }
    }
    
    private func asyncSetupExportableAsset(with inputURL: URL, completion: @escaping (AVURLAsset) -> ()) {
        let asset = AVURLAsset(url: inputURL)
        let assetKeys: [URLVideoPlayerView.LoadableAssetKeys] = [.exportable, .tracks]
        let assetKeyValues = assetKeys.map { $0.rawValue }
        
        asset.loadValuesAsynchronously(forKeys: assetKeyValues) {
            for key in assetKeys {
                var error: NSError? = nil
                let status = asset.statusOfValue(forKey: key.rawValue, error: &error)
                switch status {
                case .failed:
                    DebugLogger.shared.addDebugMessage("Asset for url: \(inputURL) failed to load value for key: \(key). Error: \(String(describing: error))")
                case .loaded:
                    if asset.isExportable {
                        completion(asset)
                    }
                default:
                    DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - asset status: \(status)")
                }
            }
        }
    }
    
    private func exportLowerQualityVideo(fromAsset asset: AVURLAsset, to outputURL: URL, completion: @escaping (AVAssetExportSession?) -> ()) {
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            completion(nil)
            return
        }
        
        try? FileManager.default.removeItem(at: outputURL)
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously {
            completion(exportSession)
        }
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
    
    internal func getCachedVideoURL(for sourceURL: URL, resolution: CGSize) -> URL? {
        let downloadedFileURL = constructFormattedURL(from: sourceURL,
                                                      expectedDirectoryURL: directoryManager.videosDirectoryURL,
                                                      size: resolution)

        return ((try? downloadedFileURL.checkResourceIsReachable()) ?? false) ? downloadedFileURL : nil
    }
    
    internal func getCachedImageURL(for sourceURL: URL, size: CGSize) -> URL? {
        let downloadedFileURL = constructFormattedURL(from: sourceURL,
                                                      expectedDirectoryURL: directoryManager.imagesDirectoryURL,
                                                      size: size)
        
        return (try? downloadedFileURL.checkResourceIsReachable()) ?? false ? downloadedFileURL : nil
    }
    
    internal func getTemporarilyCachedFileURL(for sourceURL: URL) -> URL? {
        let uncachedDownloadedFileURL = createTemporaryFileURL(from: sourceURL)
        
        return ((try? uncachedDownloadedFileURL.checkResourceIsReachable()) ?? false) ? uncachedDownloadedFileURL : nil
    }
    
    
    
    
    
    internal func videoExists(for sourceURL: URL) -> Bool {
        return downloadedFileExists(for: sourceURL, fileType: .video)
    }
    
    internal func imageExists(for sourceURL: URL) -> Bool {
        return downloadedFileExists(for: sourceURL, fileType: .image)
    }
    
    internal func uncachedFileExists(for sourceURL: URL) -> Bool {
        return downloadedFileExists(for: sourceURL, fileType: .temporary)
    }
    
    
    
    private func downloadedFileExists(for sourceURL: URL, fileType: Celestial.ResourceFileType) -> Bool {
        
        var directoryURL: URL
        
        switch fileType {
        case .video:   directoryURL = directoryManager.videosDirectoryURL
        case .image:   directoryURL = directoryManager.imagesDirectoryURL
        default:        directoryURL = directoryManager.temporaryDirectoryURL
        }
        
        let sourceURLDecomposition = decomposed(sourceURL: sourceURL)
        let actualFileName = sourceURLDecomposition.actualFileName
        
        guard let directoryContents = try? FileManager.default.contentsOfDirectory(atPath: directoryURL.path) else {
            return false
        }
        
        var fileExists: Bool = false
        
        fileExistsLoop: for storedFileName in directoryContents {
            if storedFileName.hasPrefix(actualFileName) {
                fileExists = true
                break fileExistsLoop
            }
        }
        
        return fileExists
    }
    
    internal func constructFormattedURL(from sourceURL: URL, expectedDirectoryURL: URL, size: CGSize) -> URL {
        
        // TODO
        // Determine resolution for video
//        guard size != .zero else {
//            fatalError("Invalid size. Image or video size cannot be zero: \(size)")
//        }
        
        // size: CGSize(width: 327.0, height: 246.0)
        // image name 1: URL: https://picsum.photos/id/0/5616/3744 -> becomes -> 3744-size-327.0-246.0 (no extension)
        // image name 2: URL: https://server/url/to/your/image.png -> becomes -> image-size-327.0-246.0.png
        let sizePathComponent: String = "-size-\(size.width)-\(size.height)"
        
        let sourceURLDecomposition = decomposed(sourceURL: sourceURL)
        
        var formattedFileName = sourceURLDecomposition.actualFileName + sizePathComponent
        
        if sourceURLDecomposition.fileExtension.count > 0 {
            formattedFileName += ".\(sourceURLDecomposition.fileExtension)"
        }
        let sizeFormattedURL = expectedDirectoryURL.appendingPathComponent(formattedFileName)
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Constructing formatted URL: \(sizeFormattedURL)")
        return sizeFormattedURL
    }
    
    private func decomposed(sourceURL: URL) -> SourceURLDecomposition {
        // https://whatever.com/someimage.png -> someimage
        let actualFileName = sourceURL.deletingPathExtension().lastPathComponent.lowercased()
        // https://whatever.com/someimage.png -> png
        let fileExtension = sourceURL.pathExtension.lowercased()
        
        return SourceURLDecomposition(actualFileName: actualFileName, fileExtension: fileExtension)
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
