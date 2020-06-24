//
//  GenericDownloadModel.swift
//  Pods
//
//  Created by Chrishon Wyllie on 6/23/20.
//

import Foundation

internal protocol CachableDownloadModelDelegate: class {
    
    /// This is called when the media is fully downloaded.
    /// At this point, the data can be cached.
    func cachable(_ downloadTaskRequest: DownloadTaskRequestProtocol, didFinishDownloadingTo localTemporaryFileURL: URL)
    
    /// This is called when an error occurred while downloading the media
    /// Inspect the `error` argument for a more detailed description.
    func cachable(_ downloadTaskRequest: DownloadTaskRequestProtocol, downloadFailedWith error: Error)
    
    /// This is called every time a new portion of data is received.
    /// This can be used to update your UI with the appropriate values to let users know the progress of the download
    func cachable(_ downloadTaskRequest: DownloadTaskRequestProtocol, downloadProgress progress: Float, humanReadableProgress: String)
}

internal enum DownloadTaskState {
    case none
    case paused
    case downloading
    case finished
}

public enum DownloadCompletionCacheStyle {
    case inMemory
    case fileSystem
}

///
internal protocol DownloadModelRepresentable: class {
    var sourceURL: URL { get }
    var downloadState: DownloadTaskState { get }
    var delegate: CachableDownloadModelDelegate? { get set }
    
    func update(downloadState: DownloadTaskState)
}


internal class GenericDownloadModel: DownloadModelRepresentable, CustomStringConvertible {
    var sourceURL: URL
    weak var delegate: CachableDownloadModelDelegate?
    var downloadState: DownloadTaskState = .none
    
    init(sourceURL: URL, delegate: CachableDownloadModelDelegate?) {
        self.sourceURL = sourceURL
        self.delegate = delegate
    }
    
    func update(downloadState: DownloadTaskState) {
        self.downloadState = downloadState
    }
    
    var description: String {
        return "URL: \(sourceURL) \n delegate: \(String(describing: delegate)) \n downloadState: \(downloadState)"
    }
}
