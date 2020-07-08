//
//  MiscellaneousDeclarations.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import Foundation
import UIKit.UIImage

@objc public protocol URLCachableView: class {
    
    /// The url of the requested resource
    var sourceURL: URL? { get }
    
    /// Determines whether the requested resource should be cached or not once download completes
    var cachePolicy: MultimediaCachePolicy { get }
    
    /// Determines where a downloaded resource will be stored if `cachePolicy == .allow`
    var cacheLocation: DownloadCompletionCacheLocation { get }
    
    /**
     Initializes a download model to begin a download and link its status with a receiver

    - Parameters:
       - delegate: Used to notify receiver of events related to current download of the requested resource. e.g. An image or video hosted on an external server
       - cachePolicy: Used to notify receiver of download state events such as completion, progress and errors
       - cacheLocation: Determines where a downloaded resource will be stored if `cachePolicy == .allow`
    */
    init(frame: CGRect, cachePolicy: MultimediaCachePolicy, cacheLocation: DownloadCompletionCacheLocation)
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
