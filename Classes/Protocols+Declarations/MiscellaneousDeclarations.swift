//
//  MiscellaneousDeclarations.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import Foundation
import UIKit.UIImage
import AVFoundation

@objc public protocol URLCachableView: class {
    
    /// The url of the requested resource
    var sourceURL: URL? { get }
    
    /// Determines where a downloaded resource will be stored if at all
    var cacheLocation: ResourceCacheLocation { get }
    
    /**
     Begins a download and link its status with a receiver

    - Parameters:
       - delegate: Used to notify receiver of events related to current download of the requested resource. e.g. An image or video hosted on an external server
       - cacheLocation: Determines where a downloaded resource will be stored if at all
    */
    init(frame: CGRect, cacheLocation: ResourceCacheLocation)
}

/// Delegate for notifying receiver of events related to current download of a requested resource
@objc public protocol URLCachableViewDelegate: class {
    
    /**
     Notifies receiver of errors encountered during download and/or caching

    - Parameters:
       - view: The view that will send delegate information to its receiver
       - media: The media that just finished downloading. For `URLImageView` images, this can be type-casted to a `UIImage`. For `URLVideoPlayerView`, this can be type-casted to a URL if necessary
    */
    @objc optional func urlCachableView(_ view: URLCachableView, didFinishDownloading media: Any)
    
    /**
     Notifies receiver of errors encountered during download and/or caching

    - Parameters:
       - view: The view that will send delegate information to its receiver
       - error: Error encountered during download and possible caching
    */
    @objc optional func urlCachableView(_ view: URLCachableView, downloadFailedWith error: Error)
    
    /**
     Notifies receiver of download progress prior to completion

    - Parameters:
       - view: The view that will send delegate information to its receiver
       - progress: Float value from 0.0 to 1.0 denoting current download progress of the requested resource
       - humanReadableProgress: A more easily readable version of the progress parameter
    */
    @objc optional func urlCachableView(_ view: URLCachableView, downloadProgress progress: Float, humanReadableProgress: String)
}








// MARK: - CachableAVPlayerItem

@objc public protocol CachableAVPlayerItemDelegate {
    
    /// This is called when the video file is fully downloaded.
    /// At this point, the data can be cached using the MemoryCachedVideoData struct
    func playerItem(_ playerItem: CachableAVPlayerItem, didFinishDownloading data: Data)
    
    /// This is called when an error occurred while downloading the video
    /// Inspect the `error` argument for a more detailed description.
    func playerItem(_ playerItem: CachableAVPlayerItem, downloadFailedWith error: Error)
    
    
    
    
    // Optional delegate functions
    
    
    /// Called every time a new portion of data is received.
    /// This can be used to update your UI with the appropriate values to let users know the progress of the download
    @objc optional func playerItem(_ playerItem: CachableAVPlayerItem, downloadProgress progress: CGFloat, humanReadableProgress: String)
    
    /// Called after initial prebuffering is finished,
    /// In other words, the video is ready to begin playback.
    @objc optional func playerItemReadyToPlay(_ playerItem: CachableAVPlayerItem)
    
    /// Called when the data being downloaded did not arrive in time to
    /// continue playback.
    /// Perhaps  at this point, a loading animation would be recommented to show to users
    @objc optional func playerItemPlaybackStalled(_ playerItem: CachableAVPlayerItem)
    
    
    /// Called when the video experiences an error when attempting to begin playing
    @objc optional func playerItem(_ playerItem: CachableAVPlayerItem, failedToPlayWith error: Error)
    
}










// MARK: - ObservableAVPlayer

/// Delegate for notifying receiver of status changes for AVPlayerItem
internal protocol ObservableAVPlayerDelegate: class {
    
    /**
     Notifies receiver of `AVPlayerItem.Status`

    - Parameters:
       - player: The AVPlayer that will send delegate information to its receiver
       - status: The new status for the player item. Switch on to determine when ready to play
    */
    func observablePlayer(_ player: ObservableAVPlayer, didLoadChangePlayerItem status: AVPlayerItem.Status)
}

/// Protocol that all Observable AVPlayers must conform to in order to provide relevant info to the receiver
internal protocol ObservablePlayerProtocol {
    /// Notifies receiver of `AVPlayerItem.Status`
    var delegate: ObservableAVPlayerDelegate? { get }
    
    /// Context for adding observer
    var playerItemContext: Int { get }
    
    /**
     Required initializer
 
    - Parameters:
        - playerItem: The `AVPlayerItem` which will be observed
        - delegate: Receiver of AVPlayerItem status updates
    */
    init(playerItem: AVPlayerItem, delegate: ObservableAVPlayerDelegate)
}













// MARK: - MediaResourceLoaderDelegate

internal protocol MediaResourceLoaderDelegate: class {
    
    /// This is called when the media is fully downloaded.
    /// At this point, the data can be cached.
    func resourceLoader(_ loader: MediaResourceLoader, didFinishDownloading media: Any)
    
    /// This is called when an error occurred while downloading the media
    /// Inspect the `error` argument for a more detailed description.
    func resourceLoader(_ loader: MediaResourceLoader, downloadFailedWith error: Error)
    
    /// This is called every time a new portion of data is received.
    /// This can be used to update your UI with the appropriate values to let users know the progress of the download
    func resourceLoader(_ loader: MediaResourceLoader, downloadProgress progress: CGFloat, humanReadableProgress: String)
}












// MARK: - Errors

/// Errors encountered during internal Celestial operations
enum CLSError: Error {
    case urlToDataError(String)
    case invalidSourceURLError(String)
    case nonExistentFileAtURLError(String)
}


























// MARK: - DownloadTaskManagerProtocol

/// Singleton for managing all downloads of resources from external URLs
protocol DownloadTaskManagerProtocol {
    /// Keeps track of active downloads
    var activeDownloadsContext: DownloadManagerContext { get }
    
    /// Session for downloads
    var downloadsSession: URLSession { get }
    
    /**
     Cancels all running and/or paused downloads
     */
    func cancelAllDownloads()
    
    /**
     Pauses all running downloads
    */
    func pauseAllDownloads()
    
    /**
     Resumes all paused downloads
    */
    func resumeAllDownloads()
    
    /**
     Cancels an active download

    - Parameters:
       - url: The URL of the resource
    */
    func cancelDownload(forSourceURL sourceURL: URL)
    
    /**
     Cancels an active download

    - Parameters:
       - downloadTaskRequest: The DownloadTaskRequest object that originally initiated the download.
    */
    func cancelDownload(downloadTaskRequest: DownloadTaskRequest)
    
    /**
     Pauses an active download. May be resumed

    - Parameters:
       - url: The URL of the resource
    */
    func pauseDownload(forSourceURL sourceURL: URL)
    
    /**
     Pauses an active download. May be resumed

    - Parameters:
       - downloadTaskRequest: The DownloadTaskRequest object that originally initiated the download.
    */
    func pauseDownload(downloadTaskRequest: DownloadTaskRequest)
    
    /**
     Resumes a previously paused download

    - Parameters:
       - url: The URL of the resource
    */
    func resumeDownload(forSourceURL sourceURL: URL)
    
    /**
     Resumes a previously paused download

    - Parameters:
       - downloadTaskRequest: The DownloadTaskRequest object that originally initiated the download. However in cases where the original model was deinitialized, a re-initiated model will still resume the same download
    */
    func resumeDownload(downloadTaskRequest: DownloadTaskRequest)
    
    /**
     Begins a download for a requested resource. May be paused, resumed or cancelled

    - Parameters:
       - downloadTaskRequest: The DownloadTaskRequest object used to initiate the download.
    */
    func startDownload(downloadTaskRequest: DownloadTaskRequest)
    
    
    
    
    
    /**
     Returns the download state for a given url
     
    - Parameters:
        - url: The url of the requested resource
    - Returns:
        - The `DownloadTaskState` for the given url
     */
    func downloadState(forSourceURL sourceURL: URL) -> DownloadTaskState
    
    /**
     Returns a Float value from 0.0 to 1.0 of a download if it exists and is currently in progress

    - Parameters:
       - url: The url of the resource
    - Returns:
       - Float value of download progress
    */
    func getDownloadProgress(forSourceURL sourceURL: URL) -> Float?
    
}










/// Represents current state of a download of a resource from an external URL
public enum DownloadTaskState: Int {
    /// First state of a download before it begins
    case none = 0
    /// Download has been temporarily paused. May be resumed
    case paused
    /// Download is currently in progress
    case downloading
    /// Download has finished and stored to a temporary URL, waiting to be cached if desired
    case finished
}

/// Determines where cached files will be stored if at all
@objc public enum ResourceCacheLocation: Int {
    /// Downloaded resources will be stored in local `NSCache`
    case inMemory = 0
    /// Downloaded resources will be stored in local file system
    case fileSystem
    /// Downloaded resources will not be cached
    case none
}











/// Determines what state a resource is in
/// Whether it has been cached, exists in a temporary uncached state, .etc
internal enum ResourceExistenceState: Int {
    /// The resource has completed downloading but remains in a temporary
    /// cache in the file system until URLCachableView decides what to do with it
    case uncached = 0
    /// The resource has completed downloading and is cached to either memory or file system
    case cached
    /// The resource is currently being downloaded
    case currentlyDownloading
    /// The download task for the resource has been paused
    case downloadPaused
    /// There are no pending downloads for the resource, nor does it exist anywhere. Must begin new download
    case none
}

/// File type of the resource. Used for proper identification and storage location
internal enum ResourceFileType: Int {
    case video = 0
    case image
    case temporary
    case all
}

/// Struct for identifying if a resource exists in cache, whether in memory or in file system
internal struct CachedResourceIdentifier: Codable, Equatable, Hashable, CustomStringConvertible {
    
    /// The URL pointing to the external resource
    let sourceURL: URL
    /// The file type of the resource
    let resourceType: ResourceFileType
    /// The location that the cached resource exists in: in local memory, in file system, .etc
    let cacheLocation: ResourceCacheLocation
    
    var description: String {
        let printableString = "Source URL: \(sourceURL), resourceType: \(String(reflecting: resourceType)), cacheLocation: \(String(reflecting: cacheLocation))"
        return printableString
    }
    
    /// Initializes CachedResourceIdentifier object to be used later to determine if the actual file exists and can be retrieved
    init(sourceURL: URL, resourceType: ResourceFileType, cacheLocation: ResourceCacheLocation) {
        self.sourceURL = sourceURL
        self.resourceType = resourceType
        self.cacheLocation = cacheLocation
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        sourceURL = try container.decode(URL.self, forKey: .sourceURL)
        let resourceTypeRawValue = try container.decode(Int.self, forKey: .resourceType)
        resourceType = ResourceFileType(rawValue: resourceTypeRawValue)!
        
        let cacheLocationRawValue = try container.decode(Int.self, forKey: .cacheLocation)
        cacheLocation = ResourceCacheLocation(rawValue: cacheLocationRawValue)!
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(sourceURL, forKey: .sourceURL)
        try container.encode(resourceType.rawValue, forKey: .resourceType)
        try container.encode(cacheLocation.rawValue, forKey: .cacheLocation)
    }
    
    enum CodingKeys: String, CodingKey {
        case sourceURL
        case resourceType
        case cacheLocation
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(sourceURL.absoluteString)
    }

    static func ==(lhs: CachedResourceIdentifier, rhs: CachedResourceIdentifier) -> Bool {
        return lhs.sourceURL.absoluteString == rhs.sourceURL.absoluteString
    }
}













/// Delegate for notifying receiver of progress, completion and possible errors
/// of a resource located at a external URL
internal protocol CachableDownloadModelDelegate: class {
    
    /**
     Notifies receiver that media has been finished downloading to a temporary file location.

    - Parameters:
       - downloadTaskRequest: The DownloadTaskRequest object that finished the download. Note, this object has been invalidated after completion.
       - intermediateTemporaryFileURL: The temporary url pointing to the downloaded resource after it is moved to a retrievable URL
    */
    func cachable(_ downloadTaskRequest: DownloadTaskRequestProtocol, didFinishDownloadingTo intermediateTemporaryFileURL: URL)
    
    /**
     Notifies receiver that the download has failed.

    - Parameters:
       - downloadTaskRequest: The DownloadTaskRequest object that finished the download. Note, this object has been invalidated after completion.
       - error: Error encour
    */
    func cachable(_ downloadTaskRequest: DownloadTaskRequestProtocol, downloadFailedWith error: Error)
    
    /**
     Notifies receiver of download progress.

    - Parameters:
       - downloadTaskRequest: The DownloadTaskRequest object that finished the download. Note, this object has been invalidated after completion.
       - progress: The current progress of the download from 0.0 to 1.0
       - humanReadableProgress: A easily readable version of the progress. For convenience
    */
    func cachable(_ downloadTaskRequest: DownloadTaskRequestProtocol, downloadProgress progress: Float, humanReadableProgress: String)
}











public struct TestURLs {
    
    public struct Videos {
        public static var urlStrings: [String] = [
            "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
            "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
            "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
            "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
            "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4",
            "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
            "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4",
            "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4"
        ]
    }
}
