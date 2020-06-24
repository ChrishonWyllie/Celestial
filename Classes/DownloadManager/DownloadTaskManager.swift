//
//  DownloadTaskManager.swift
//  Celestial
//
//  Created by Chrishon Wyllie on 6/22/20.
//

import Foundation

/// Singleton for managing all downloads of resources from external URLs
protocol DownloadTaskManagerProtocol {
    /// Dictionary of currently active or paused downloads.
    /// Key: the URL of the requested resource
    /// Value: the `DownloadTaskRequest` for the request resource
    var activeDownloads: [URL: DownloadTaskRequest] { get }
    
    /// Session for downloads
    var downloadsSession: URLSession { get }
    
    /**
     Cancels an active download

    - Parameters:
       - url: The URL of the resource
    */
    func cancelDownload(for url: URL)
    
    /**
     Cancels an active download

    - Parameters:
       - model: The DownloadModel object that originally initiated the download.
    */
    func cancelDownload(model: DownloadModelRepresentable)
    
    /**
     Pauses an active download. May be resumed

    - Parameters:
       - url: The URL of the resource
    */
    func pauseDownload(for url: URL)
    
    /**
     Pauses an active download. May be resumed

    - Parameters:
       - model: The DownloadModel object that originally initiated the download.
    */
    func pauseDownload(model: DownloadModelRepresentable)
    
    /**
     Resumes a previously paused download

    - Parameters:
       - url: The URL of the resource
    */
    func resumeDownload(for url: URL)
    
    /**
     Resumes a previously paused download

    - Parameters:
       - model: The DownloadModel object that originally initiated the download. However in cases where the original model was deinitialized, a re-initiated model will still resume the same download
    */
    func resumeDownload(model: DownloadModelRepresentable)
    
    /**
     Begins a download for a requested resource. May be paused, resumed or cancelled

    - Parameters:
       - model: The DownloadModel object used to initiate the download.
    */
    func startDownload(model: DownloadModelRepresentable)
    
    
    
    /**
     Returns a boolean denoting whether a download is currently active and in progress

    - Parameters:
       - url: The url of the resource
    - Returns:
       - Boolean value of whether the download for the requested resource is currently in progress
    */
    func downloadIsInProgress(for url: URL) -> Bool
    
    /**
     Returns a boolean denoting whether a download has previously been initiated but is in a paused state

    - Parameters:
       - url: The url of the resource
    - Returns:
       - Boolean value of whether the download for the requested resource is in a paused state
    */
    func downloadIsPaused(for url: URL) -> Bool
    
    /**
     Returns a Float value from 0.0 to 1.0 of a download if it exists and is currently in progress

    - Parameters:
       - url: The url of the resource
    - Returns:
       - Float value of download progress
    */
    func getDownloadProgress(for url: URL) -> Float?
    
}

/// Singleton for managing all downloads of resources from external URLs
class DownloadTaskManager: NSObject, DownloadTaskManagerProtocol {
    
    internal static let shared = DownloadTaskManager()
    
    private(set) var activeDownloads: [URL : DownloadTaskRequest] = [:]
    
    private(set) lazy var downloadsSession: URLSession = {
        let identifier = "com.chrishonwyllie.Celestial.backgroundSession"
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    
    
    
    
    
    
    
    
    
    
    private override init() {
        super.init()
    }
    
    
    
    
    
    
    
    
    
    
    internal func cancelDownload(for url: URL) {
        guard let download = activeDownloads[url] else {
            return
        }
        download.task?.cancel()

        activeDownloads[url] = nil
    }
    internal func cancelDownload(model: DownloadModelRepresentable) {
        cancelDownload(for: model.sourceURL)
    }
    
    internal func pauseDownload(for url: URL) {
        guard let download = activeDownloads[url] else {
            return
        }
        
        guard download.downloadModel.downloadState == .downloading else {
            return
        }
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - pausing download for url: \(url)")
        
        download.task?.cancel(byProducingResumeData: { data in
            download.resumeData = data
        })

        download.downloadModel.update(downloadState: .paused)
    }
    internal func pauseDownload(model: DownloadModelRepresentable) {
        pauseDownload(for: model.sourceURL)
    }
    
    internal func resumeDownload(for url: URL) {
        guard let download = activeDownloads[url] else {
            return
        }
             
        if let resumeData = download.resumeData {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - resuming download for url from resume data: \(url)")
            download.task = downloadsSession.downloadTask(withResumeData: resumeData)
        } else {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - resuming download for url (from scratch): \(url)")
            download.task = downloadsSession.downloadTask(with: url)
        }
             
        download.task?.resume()
        download.downloadModel.update(downloadState: .downloading)
    }
    internal func resumeDownload(model: DownloadModelRepresentable) {
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - using new download: \(String(describing: model.delegate))")
        activeDownloads[model.sourceURL]?.downloadModel.delegate = model.delegate
        resumeDownload(for: model.sourceURL)
    }
    
    internal func startDownload(model: DownloadModelRepresentable) {
        if let _ = activeDownloads[model.sourceURL] {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Attempted to start a download, but an active download already exists")
            resumeDownload(model: model)
            return
        }
        beginFreshDownload(model: model)
    }
    
    private func beginFreshDownload(model: DownloadModelRepresentable) {
        DebugLogger.shared.addDebugMessage("starting download for url: \(model.sourceURL)")
        // 1
        let download = DownloadTaskRequest(downloadModel: model)
        // 2
        download.task = downloadsSession.downloadTask(with: model.sourceURL)
        // 3
        download.task?.resume()
        // 4
        download.downloadModel.update(downloadState: .downloading)
        // 5
        activeDownloads[model.sourceURL] = download
    }
    
}






// MARK: - Utility

extension DownloadTaskManager {
    
    internal func downloadIsInProgress(for url: URL) -> Bool {
        guard let download = activeDownloads[url] else {
            return false
        }
        return download.downloadModel.downloadState == .downloading
    }
    
    internal func downloadIsPaused(for url: URL) -> Bool {
        guard let download = activeDownloads[url] else {
            return false
        }
        return download.downloadModel.downloadState == .paused
    }
    
    internal func getDownloadProgress(for url: URL) -> Float? {
        guard let download = activeDownloads[url] else {
            return nil
        }
        return download.progress
    }
}




// MARK: - URLSessionDownloadDelegate

extension DownloadTaskManager: URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        guard let sourceURL = downloadTask.originalRequest?.url else {
            return
        }
      
        guard let download = activeDownloads[sourceURL] else {
            return
        }
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - finished download for url: \(sourceURL)")
        activeDownloads[sourceURL] = nil
      
        moveToIntermediateTemporaryFile(originalTemporaryURL: location, download: download)
    }
    
    private func moveToIntermediateTemporaryFile(originalTemporaryURL: URL, download: DownloadTaskRequest) {
        do {
            let temporaryFileURL = try FileStorageManager.shared.moveToIntermediateTemporaryURL(originalTemporaryURL: originalTemporaryURL)
            
            download.downloadModel.update(downloadState: .finished)
            
            // Notify delegate
            download.downloadModel.delegate?.cachable(download, didFinishDownloadingTo: temporaryFileURL)
            
        } catch let error {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Could not copy file to disk: \(error.localizedDescription)")
            download.downloadModel.delegate?.cachable(download, downloadFailedWith: error)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        
        guard let sourceURL = downloadTask.originalRequest?.url else {
            return
        }
        
        guard let download = activeDownloads[sourceURL] else {
            return
        }
        
        let (downloadProgress, humanReadableDownloadProgress) = Utility.shared.getDownloadProgress(totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        
        download.progress = downloadProgress
        
        // Notify delegate
        if download.downloadModel.delegate == nil {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - delegate nil for download object: \(download.downloadModel)")
        }
        download.downloadModel.delegate?.cachable(download, downloadProgress: downloadProgress, humanReadableProgress: humanReadableDownloadProgress)
    }
    
//    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//
//        guard let download = activeDownloads[sourceURL] else {
//            return
//        }
//        if let error = error {
//
//        }
//    }

}





//extension DownloadTaskManager: URLSessionDelegate {
//    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
//        DispatchQueue.main.async {
//
//            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
//                let completionHandler = appDelegate.backgroundSessionCompletionHandler {
//                appDelegate.backgroundSessionCompletionHandler = nil
//                completionHandler()
//            }
//        }
//    }
//}


