//
//  MemoryCachedVideoData.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/29/19.
//

import Foundation

/// A  "container" for storing the videos into the cache.
/// When caching the Data associated with a video file, recreating the video at a later date requires
/// the original mime type and file extension. Therefore, this information is stored along with the Data itself.
public struct MemoryCachedVideoData {
    /// The data represented by the video file that was downloaded using an external URL
    public let videoData: Data
    /// The original mime type of the video is related to the file extension.
    /// Look up mime types.
    /// For example, the mimeType for a .mov file is "video/quicktime"
    public let originalURLMimeType: String
    
    /// The original file extension. e.g. ".mov", ".mp4"
    public let originalURLFileExtension: String
}
