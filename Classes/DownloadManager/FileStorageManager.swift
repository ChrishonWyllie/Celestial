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
internal class FileStorageDirectoryManager: NSObject {
    
    // NOTE
    // For hiding access to urls
    
    fileprivate var documentsDirectoryURL: URL {
        return FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory,
                                        in: FileManager.SearchPathDomainMask.userDomainMask).first!
    }
    
    fileprivate var temporaryDirectoryURL: URL {
        return FileManager.default.temporaryDirectory
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
     Deletes a file at a specified location

    - Parameters:
       - location: The local URL of the file
    - Returns:
       - Boolean value of whether the file was successfully deleted
    */
    @discardableResult func deleteFile(at location: URL) -> Bool
    
    /**
     Deletes the video that was created from the source URL. Will delete all copies of the video

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
    func clearCache(fileType: ResourceFileType)
    
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
     Resizes the video

    - Parameters:
       - sourceURL: The url of the resource that has been requested
       - intermediateTemporaryFileURL: The intermediate file url that the downloaded resource has been moved to after the `URLSessionDownloadTask` has completed
       - completion: Executes completion block with a URL pointing to a compressed video
    
    */
    func cachedAndResizedVideo(sourceURL: URL, intermediateTemporaryFileURL: URL, completion: @escaping (_ compressedVideoURL: URL?) -> ())
    
    /**
     Resizes the image with a given point size and caches it

    - Parameters:
       - sourceURL: The url of the resource that has been requested
       - size: The iOS point size to downsize the image to
       - intermediateTemporaryFileURL: The intermediate file url that the downloaded resource has been moved to after the `URLSessionDownloadTask` has completed
     
    - Returns:
       - A image of the newly resized and cached resource
    */
    func cachedAndResizedImage(sourceURL: URL, size: CGSize, intermediateTemporaryFileURL: URL, completion: @escaping (_ resizedImage: UIImage?) -> ())
    
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


internal class FileStorageManager: NSObject, FileStorageMangerProtocol {
    
    // MARK: - Variables
    
    internal static let shared = FileStorageManager()
    
    internal let directoryManager = FileStorageDirectoryManager()
    
   
    
    
    
    // MARK: - Initializers
    
    private override init() {
        super.init()
    }
    
    
    
    
    
    
    
    
    
    
    // MARK: - Functions
    
    @discardableResult internal func deleteFile(at location: URL) -> Bool {
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Attempting to delete file for path: \(location.path)")
        return ((try? FileManager.default.removeItem(atPath: location.path)) != nil)
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
    
    internal func clearCache(fileType: ResourceFileType) {
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
            _ = getInfoForDirectory(at: directoryURL)
            
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
        deleteFile(at: intermediateTemporaryFileURL)
        
        guard ((try? originalTemporaryURL.checkResourceIsReachable()) != nil) else {
            fatalError("The original temporary file URL from download does not exist. URL: \(originalTemporaryURL)")
        }
        
        try FileManager.default.moveItem(at: originalTemporaryURL, to: intermediateTemporaryFileURL)
        return intermediateTemporaryFileURL
    }
    
    internal func createTemporaryFileURL(from sourceURL: URL) -> URL {
        
        let localFileName = sourceURL.localUniqueFileName()
        let fileExtension = sourceURL.pathExtension
        
        let intermediateTemporaryFileURL =
            directoryManager.temporaryDirectoryURL
                .appendingPathComponent(localFileName)
                .appendingPathExtension(fileExtension)
        
        return intermediateTemporaryFileURL
    }
    
    internal func cachedAndResizedVideo(sourceURL: URL,
                                        intermediateTemporaryFileURL: URL,
                                        completion: @escaping (_ compressedVideoURL: URL?) -> ()) {

        decreaseVideoQuality(sourceURL: sourceURL, inputURL: intermediateTemporaryFileURL) { [weak self] (sizeFormattedCompressedURL) in
            guard let strongSelf = self else { return }
            // Finally delete the local intermediate file
            DispatchQueue.global(qos: .background).async {
                strongSelf.deleteFile(at: intermediateTemporaryFileURL)
            }
            completion(sizeFormattedCompressedURL)
        }
    }
    
    internal func decreaseVideoQuality(sourceURL: URL, inputURL: URL, completion: @escaping (URL?) -> ()) {
        
        if let uncompressedVideoData = try? Data(contentsOf: inputURL) {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - File size before compression: \(uncompressedVideoData.sizeInMB)")
        }
        
        let assetKeys: [URLVideoPlayerView.LoadableAssetKeys] = [.tracks, .exportable]
        DispatchQueue.global(qos: .background).async {
            AVURLAsset.prepareUsableAsset(withAssetKeys: assetKeys, inputURL: inputURL) { [weak self] (exportableAsset, error) in
                guard let strongSelf = self else { return }
                if let error = error {
                    fatalError("Error loading video from url: \(sourceURL). Error: \(String(describing: error))")
                }
                
                let outputURL = strongSelf.constructFormattedURL(from: sourceURL,
                                                                 expectedDirectoryURL: strongSelf.directoryManager.videosDirectoryURL,
                                                                 size: nil)
                
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
                        completion(nil)
                        
                    case .cancelled:
                        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - export for url: \(outputURL) cancelled")
                        completion(nil)
                        
                    case .unknown: break
                    case .waiting: break
                    @unknown default:
                        fatalError()
                    }
                }
            }
        }
    }
    
    private func exportLowerQualityVideo(fromAsset asset: AVURLAsset,
                                         to outputURL: URL,
                                         completion: @escaping (AVAssetExportSession?) -> ()) {
        
        guard asset.isExportable else {
            completion(nil)
            return
        }
        
        try? FileManager.default.removeItem(at: outputURL)

        let composition = AVMutableComposition()
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))

        guard
            let sourceVideoTrack = asset.tracks(withMediaType: AVMediaType.video).first,
            let sourceAudioTrack = asset.tracks(withMediaType: AVMediaType.audio).first
            else {
                completion(nil)
                return
        }
        
        do {
            try compositionVideoTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: asset.duration), of: sourceVideoTrack, at: CMTime.zero)
            try compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: asset.duration), of: sourceAudioTrack, at: CMTime.zero)
        } catch(_) {
            completion(nil)
            return
        }

        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: composition)
        var preset: String = AVAssetExportPresetPassthrough
        if compatiblePresets.contains(AVAssetExportPresetMediumQuality) { preset = AVAssetExportPresetMediumQuality }
        
        guard
            let exportSession = AVAssetExportSession(asset: composition, presetName: preset),
            exportSession.supportedFileTypes.contains(AVFileType.mp4) else {
            completion(nil)
            return
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mp4
        let startTime = CMTimeMake(value: 0, timescale: 1)
        let timeRange = CMTimeRangeMake(start: startTime, duration: asset.duration)
        exportSession.timeRange = timeRange
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously {
            completion(exportSession)
        }
    }
    
    internal func cachedAndResizedImage(sourceURL: URL, size: CGSize, intermediateTemporaryFileURL: URL, completion: @escaping (_ resizedImage: UIImage?) -> ()) {
        
        let sizeFormattedURL = constructFormattedURL(from: sourceURL, expectedDirectoryURL: directoryManager.imagesDirectoryURL, size: size)
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - new size formatted url: \(sizeFormattedURL.path)")
        
        do {
            // Create Data from url
            let imageDataFromTemporaryFileURL: Data = try Data(contentsOf: intermediateTemporaryFileURL)
            
            // Re-create the originally downloaded image
            guard let imageFromTemporaryFileURL: UIImage = UIImage(data: imageDataFromTemporaryFileURL) else {
                completion(nil)
                deleteFile(at: intermediateTemporaryFileURL)
                return
            }
            
            // Downsize this image
            guard let resizedImage: UIImage = imageFromTemporaryFileURL.resize(size: size) else {
                completion(nil)
                deleteFile(at: intermediateTemporaryFileURL)
                return
            }
            
            // Convert downsized image back to Data
            guard let resizedImageData: Data = resizedImage.pngData() else {
                completion(nil)
                deleteFile(at: intermediateTemporaryFileURL)
                return
            }
            
            // Finally, write this downsized image Data to the newly created permanent url
            try resizedImageData.write(to: sizeFormattedURL)
            
            completion(resizedImage)
            
        } catch let error {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error caching and downsizing the downloaded image for source url: \(sourceURL). Error: \(error)")
            
            completion(nil)
        }
        
        // Finally delete the local intermediate file
        deleteFile(at: intermediateTemporaryFileURL)
        
    }
    
    internal func getCachedVideoURL(for sourceURL: URL) -> URL? {
        
        guard let storedFileInfo = getInfoForStoredResource(matchingSourceURL: sourceURL, fileType: .video) else {
            return nil
        }
        
        if storedFileInfo.fileSize == 0 {
            deleteFile(at: storedFileInfo.fileURL)
            return nil
        }

        return storedFileInfo.fileURL
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
    
    
    
    private func downloadedFileExists(for sourceURL: URL, fileType: ResourceFileType) -> Bool {
        
        var fileExists: Bool = false
        
        var directoryURL: URL
        
        switch fileType {
        case .video:   directoryURL = directoryManager.videosDirectoryURL
        case .image:   directoryURL = directoryManager.imagesDirectoryURL
        default:       directoryURL = directoryManager.temporaryDirectoryURL
        }
        
        let localFileName = sourceURL.localUniqueFileName()
        
        if fileType == .video {
            // TODO
            // Videos do not have multiple sizes at this time 07/13/2020
            // Therefore, the stored fileURL will not contain any special suffixes
            let completeStoredFileURL = directoryURL
                .appendingPathComponent(localFileName)
                .appendingPathExtension(sourceURL.pathExtension)
            
            guard ((try? completeStoredFileURL.checkResourceIsReachable()) != nil) else {
                return false
            }
            
            guard let fileAttributes = try? FileManager.default.attributesOfItem(atPath: completeStoredFileURL.path) else {
                return false
            }
            
            if StoredFile(fileAttributes: fileAttributes, fileURL: completeStoredFileURL).fileSize == 0 {
                deleteFile(at: completeStoredFileURL)
                return false
            } else {
                return true
            }
        }
        
        guard
            let directoryContents = try? FileManager.default.contentsOfDirectory(atPath: directoryURL.path)
            else {
            return false
        }
        
        
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Checking if downloaded file with local file name: \(localFileName) exists in file system directory: \(directoryURL). Directory contents: \(directoryContents)")
        
        fileExistsLoop: for storedFileName in directoryContents {
            if storedFileName.hasPrefix(localFileName) {
                
                let completeStoredFileURL = directoryURL.appendingPathComponent(storedFileName)
                guard ((try? completeStoredFileURL.checkResourceIsReachable()) != nil) else {
                    fileExists = false
                    break fileExistsLoop
                }
                
                
                do {
                    let fileAttributes = try FileManager.default.attributesOfItem(atPath: completeStoredFileURL.path)
                    let fileInfo = StoredFile(fileAttributes: fileAttributes, fileURL: completeStoredFileURL)
                    
                    // If the data for this file is 0,
                    // there may have been an error during download/caching
                    // Perhaps use of AVAssetExportSession interrupted from
                    // app going to background
                    // or otherwise.
                    // In which case, the file exists but is empty
                    if fileInfo.fileSize == 0 {
                        deleteFile(at: completeStoredFileURL)
                        fileExists = false
                    } else {
                        fileExists = true
                        break fileExistsLoop
                    }
                    
                } catch let error {
                    DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error getting contents of URL: \(completeStoredFileURL) as Data. Error: \(error)")
                    
                    deleteFile(at: completeStoredFileURL)
                    fileExists = false
                    break fileExistsLoop
                }
            }
        }
        
        return fileExists
    }
    
    internal func constructFormattedURL(from sourceURL: URL, expectedDirectoryURL: URL, size: CGSize?) -> URL {
        
        // size: CGSize(width: 327.0, height: 246.0)
        // image name 1: URL: https://picsum.photos/id/0/5616/3744 -> becomes -> 3744-size-327.0-246.0 (no extension)
        // image name 2: URL: https://server/url/to/your/image.png -> becomes -> image-size-327-0-246-0.png
        
        var formattedFileName = sourceURL.localUniqueFileName()
        let fileExtension = sourceURL.pathExtension
        
        if let size = size {
            let width = String(describing: size.width).replacingOccurrences(of: ".", with: "-")
            let height = String(describing: size.height).replacingOccurrences(of: ".", with: "-")
            let sizePathComponent: String = "-size-\(width)-\(height)"
            
            formattedFileName += sizePathComponent
        }
        
        let sizeFormattedURL = expectedDirectoryURL
            .appendingPathComponent(formattedFileName)
            .appendingPathExtension(fileExtension)
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Constructing formatted URL: \(sizeFormattedURL)")
        return sizeFormattedURL
    }
    
    private func getInfoForDirectory(at directoryURL: URL) -> [StoredFile] {
        
        var info: [StoredFile] = []
        
        guard let directoryContents = try? FileManager.default.contentsOfDirectory(atPath: directoryURL.path) else {
            return []
        }
        
        let folderSize = FileManager.default.sizeOfFolder(at: directoryURL.path)
        let formattedFolderSize = FileManager.default.format(size: folderSize)
        
        DebugLogger.shared.addDebugMessage("\n\(String(describing: type(of: self))) - Found \(String(describing: directoryContents.count))  items in directory with url: \(directoryURL). Folder size: \(formattedFolderSize)")
        
        do {
            for fileName in directoryContents {
                let fileURL = directoryURL.appendingPathComponent(fileName)

                let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                let fileInfo = StoredFile(fileAttributes: fileAttributes, fileURL: fileURL)
                info.append(fileInfo)
            }
        } catch let error {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error getting attributes of item in directory: \(directoryURL.path). Error: \(error)")
        }
        
        return info
    }
    
    internal func getCacheInfo() -> [StoredFile] {
        return getInfoForDirectory(at: directoryManager.videosDirectoryURL) +
            getInfoForDirectory(at: directoryManager.imagesDirectoryURL)
        
    }
    
    internal func getInfoForStoredResource(matchingSourceURL sourceURL: URL, fileType: ResourceFileType) -> StoredFile? {
        var directoryURL: URL
        
        switch fileType {
        case .video:   directoryURL = directoryManager.videosDirectoryURL
        case .image:   directoryURL = directoryManager.imagesDirectoryURL
        default:       directoryURL = directoryManager.temporaryDirectoryURL
        }
        
        // TODO
        // NOTE
        // This only works for videos
        // Will return nil since image files
        // have size suffixes
        
        var cachedResourceURL: URL!
        
        switch fileType {
        case .video:
            cachedResourceURL = constructFormattedURL(from: sourceURL, expectedDirectoryURL: directoryURL, size: nil)
        default:
            fatalError("Not implemented")
        }

        guard ((try? cachedResourceURL.checkResourceIsReachable()) != nil) else {
            return nil
        }
        
        guard let fileAttributes = try? FileManager.default.attributesOfItem(atPath: cachedResourceURL.path) else {
            return nil
        }
        
        return StoredFile(fileAttributes: fileAttributes, fileURL: cachedResourceURL)
    }
}

internal struct StoredFile: CustomStringConvertible {
    let fileAttributes: [FileAttributeKey: Any]
    let fileSize: Int64
    let formattedFileSize: String
    let fileType: String
    let filecreationDate: Date?
    let fileURL: URL
    
    var description: String {
        let printableString = "File URL: \(fileURL) \n File size: \(fileSize) \n Formatted file size: \(formattedFileSize) \n File type: \(fileType) \n File creation date: \(String(describing: filecreationDate))"
        return printableString
    }
    
    init(fileAttributes: [FileAttributeKey: Any], fileURL: URL) {
        self.fileAttributes = fileAttributes
        self.fileURL = fileURL
        
        fileSize = fileAttributes[FileAttributeKey.size] as? Int64 ?? 0
        formattedFileSize = FileManager.default.format(size: fileSize)
        fileType = fileAttributes[FileAttributeKey.type] as? String ?? ""
        filecreationDate = fileAttributes[FileAttributeKey.creationDate] as? Date
    }
}
