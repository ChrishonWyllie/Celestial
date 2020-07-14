//
//  GenericDownloadModel.swift
//  Pods
//
//  Created by Chrishon Wyllie on 6/23/20.
//

import Foundation

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

/// Model used to initiate a download and link the state of the download with its receiver.
/// May be used to notify of updates such as progress, errors and completion
internal protocol DownloadModelRepresentable: class {
    /// The URL of the resource to be downloaded
    var sourceURL: URL { get }
    /// The state of the current download. For updating UI with download state,
    /// it is best to use the `CachableDownloadModelDelegate`
    var downloadState: DownloadTaskState { get }
    /// Used to notify receiver of download state events such as completion, progress and errors
    var delegate: CachableDownloadModelDelegate? { get set }
    
    /// Updates the download state
    /**
     Updates the download state

    - Parameters:
       - downloadState: The new current state of the download
    */
    func update(downloadState: DownloadTaskState)
    
    /**
     Initializes a download model to begin a download and link its status with a receiver

    - Parameters:
       - sourceURL: The URL of the resource to be downloaded.
       - delegate: Used to notify receiver of download state events such as completion, progress and errors
    */
    init(sourceURL: URL, delegate: CachableDownloadModelDelegate?)
}

/// Model used to initiate a download and link the state of the download with its receiver.
/// May be used to notify of updates such as progress, errors and completion
internal class GenericDownloadModel: DownloadModelRepresentable, CustomStringConvertible {
    private(set) var sourceURL: URL
    private(set) var downloadState: DownloadTaskState = .none
    weak var delegate: CachableDownloadModelDelegate?
    
    required init(sourceURL: URL, delegate: CachableDownloadModelDelegate?) {
        self.sourceURL = sourceURL
        self.delegate = delegate
    }
    
    func update(downloadState: DownloadTaskState) {
        self.downloadState = downloadState
    }
    
    var description: String {
        return "\(String(describing: type(of: self))) - URL: \(sourceURL) \n delegate: \(String(describing: delegate)) \n downloadState: \(downloadState)"
    }
}
