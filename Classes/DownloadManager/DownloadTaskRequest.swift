//
//  DownloadTaskRequest.swift
//  Pods
//
//  Created by Chrishon Wyllie on 6/23/20.
//

import Foundation

/// Initiates a download from a `DownloadModelRepresentable` object
internal protocol DownloadTaskRequestProtocol {
    /// Current progress of a download. To update UI, use `CachableDownloadModelDelegate`
    var progress: Float { get }
    /// Partial Data as a result of pausing a download. May be used to resume if desired
    var resumeData: Data? { get }
    /// `URLSessionDownloadTask` used to download the desired resource
    var task: URLSessionDownloadTask? { get }
    /// Model used to initiate a download and link the state of the download with its receiver.
    /// May be used to notify of updates such as progress, errors and completion
    var downloadModel: DownloadModelRepresentable { get }
    
    /**
     Initializes a object representing a download task as well as supporting information

    - Parameters:
       - downloadModel: The DownloadModel used to initiate the request with a source URL.
    */
    init(downloadModel: DownloadModelRepresentable)
}

/// Initiates a download from a `DownloadModelRepresentable` object
internal class DownloadTaskRequest: DownloadTaskRequestProtocol {
    var progress: Float = 0
    var resumeData: Data?
    var task: URLSessionDownloadTask?
    var downloadModel: DownloadModelRepresentable
    
    required init(downloadModel: DownloadModelRepresentable) {
        self.downloadModel = downloadModel
    }
}
