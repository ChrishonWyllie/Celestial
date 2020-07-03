//
//  DownloadTaskHandler.swift
//  Pods
//
//  Created by Chrishon Wyllie on 1/5/20.
//

import Foundation

/// Provides a set of closures that provide extra flexibility to classes that implement URLSession downloadTask.
/// For example, in the case of URLImageView, this allows for observing download completion, download progress and possible errors all from
/// a single function. i.e., no need to use the URLImageViewDelegate.
internal struct DownloadTaskHandler<T> {
    
    /// Completes with a UIImage when the download completes
    var completionHandler: DownloadTaskCompletionHandler<T>?
    
    /// Provides updates with progress using 1.0 as maximum value until download completes.
    var progressHandler: DownloadTaskProgressHandler?
    
    /// Provides Error if one occurs during URLSession downloadTask
    var errorHandler: DownloadTaskErrorHandler?
}

/// Closure for providing the specified/expected data type back to the caller
public typealias DownloadTaskCompletionHandler<T> = (T) -> Void

/// Closure for providing the current download progress as provided by URLSession download task delegate back to the caller
public typealias DownloadTaskProgressHandler = (Float) -> Void

/// Closure for providing any possible errors that occur during download progress back to the caller
public typealias DownloadTaskErrorHandler = (Error) -> Void

public typealias OptionalCompletionHandler = (() -> ())?
