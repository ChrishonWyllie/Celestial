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

/// Represents current state of a download of a resource from an external URL
public enum DownloadTaskState {
    /// First state of a download before it begins
    case none
    /// Download has been temporarily paused. May be resumed
    case paused
    /// Download is currently in progress
    case downloading
    /// Download has finished and stored to a temporary URL, waiting to be cached if desired
    case finished
}

/// Determines where cached files will be stored if `cachePolicy == .allow`
@objc public enum DownloadCompletionCacheLocation: Int {
    /// Downloaded resources will be stored in local `NSCache`
    case inMemory = 0
    /// Downloaded resources will be stored in local file system
    case fileSystem
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
    var sourceURL: URL
    weak var delegate: CachableDownloadModelDelegate?
    var downloadState: DownloadTaskState = .none
    
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
