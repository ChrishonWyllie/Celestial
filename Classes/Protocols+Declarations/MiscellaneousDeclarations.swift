//
//  MiscellaneousDeclarations.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import Foundation











// MARK: - URLImageView

public protocol URLImageViewDelegate: class {
    func urlImageView(_ view: URLImageView, downloadCompletedAt urlString: String)
    func urlImageView(_ view: URLImageView, downloadFailedWith error: Error)
    func urlImageView(_ view: URLImageView, downloadProgress progress: CGFloat, humanReadableProgress: String)
}









// MARK: - CachableAVPlayerItem

@objc public protocol CachableAVPlayerItemDelegate {
    
    /// Is called when the media file is fully downloaded.
    @objc optional func playerItem(_ playerItem: CachableAVPlayerItem, didFinishDownloadingData data: Data)
    
    /// Is called every time a new portion of data is received.
    @objc optional func playerItem(_ playerItem: CachableAVPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int)
    
    /// Is called after initial prebuffering is finished, means
    /// we are ready to play.
    @objc optional func playerItemReadyToPlay(_ playerItem: CachableAVPlayerItem)
    
    /// Is called when the data being downloaded did not arrive in time to
    /// continue playback.
    @objc optional func playerItemPlaybackStalled(_ playerItem: CachableAVPlayerItem)
    
    /// Is called on downloading error.
    @objc optional func playerItem(_ playerItem: CachableAVPlayerItem, downloadingFailedWith error: Error)
    
}
