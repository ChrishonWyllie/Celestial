//
//  MiscellaneousDeclarations.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import Foundation
import UIKit.UIImage

// MARK: - URLImageView

@objc public protocol URLImageViewDelegate: class {
    
    /// This is called when the image is fully downloaded.
    /// At this point, the data can be cached.
    func urlImageView(_ view: URLImageView, didFinishDownloading image: UIImage)
    
    /// This is called when an error occurred while downloading the image
    /// Inspect the `error` argument for a more detailed description.
    func urlImageView(_ view: URLImageView, downloadFailedWith error: Error)
    
    
    
    
    // Optional delegate functions
    
    /// This is called every time a new portion of data is received.
    /// This can be used to update your UI with the appropriate values to let users know the progress of the download
    @objc optional func urlImageView(_ view: URLImageView, downloadProgress progress: CGFloat, humanReadableProgress: String)
}









// MARK: - CachableAVPlayerItem

@objc public protocol CachableAVPlayerItemDelegate {
    
    /// This is called when the video file is fully downloaded.
    /// At this point, the data can be cached using the OriginalVideoData struct
    func playerItem(_ playerItem: CachableAVPlayerItem, didFinishDownloading data: Data)
    
    /// This is called when an error occurred while downloading the video
    /// Inspect the `error` argument for a more detailed description.
    func playerItem(_ playerItem: CachableAVPlayerItem, downloadFailedWith error: Error)
    
    
    
    
    // Optional delegate functions
    
    
    /// This is called every time a new portion of data is received.
    /// This can be used to update your UI with the appropriate values to let users know the progress of the download
    @objc optional func playerItem(_ playerItem: CachableAVPlayerItem, downloadProgress progress: CGFloat, humanReadableProgress: String)
    
    /// This is called after initial prebuffering is finished,
    /// In other words, the video is ready to begin playback.
    @objc optional func playerItemReadyToPlay(_ playerItem: CachableAVPlayerItem)
    
    /// This is called when the data being downloaded did not arrive in time to
    /// continue playback.
    /// Perhaps  at this point, a loading animation would be recommented to show to users
    @objc optional func playerItemPlaybackStalled(_ playerItem: CachableAVPlayerItem)
    
}
