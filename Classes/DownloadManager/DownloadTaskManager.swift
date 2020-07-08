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
     Returns the download state for a given url
     
    - Parameters:
        - url: The url of the requested resource
    - Returns:
        - The `DownloadTaskState` for the given url
     */
    func downloadState(for url: URL) -> DownloadTaskState
    
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
    
    var activeDownloads: [URL : DownloadTaskRequest] {
        var downloads: [URL : DownloadTaskRequest]!
        
        concurrentQueue.sync {
            downloads = self.threadUnsafeActiveDownloads
        }
        return downloads
    }
    
    private var threadUnsafeActiveDownloads: [URL : DownloadTaskRequest] = [:]
    
    private let concurrentQueue = DispatchQueue(label: "com.chrishonwyllie.Celestial.downloadTaskQueue",
                                                attributes: .concurrent)
    
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

        threadUnsafeActiveDownloads[url] = nil
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
        exchangeDownloadModel(newModel: model)
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
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - starting download for url: \(model.sourceURL)")
        concurrentQueue.async(flags: .barrier) { [weak self] in
        
            guard let strongSelf = self else {
                return
            }
            
            // 1
            let download = DownloadTaskRequest(downloadModel: model)
            // 2
            download.task = strongSelf.downloadsSession.downloadTask(with: model.sourceURL)
            // 3
            download.task?.resume()
            // 4
            download.downloadModel.update(downloadState: .downloading)
            // 5
            strongSelf.threadUnsafeActiveDownloads[model.sourceURL] = download

        }
    }
}






// MARK: - Utility

extension DownloadTaskManager {
    
    internal func downloadState(for url: URL) -> DownloadTaskState {
        guard let download = activeDownloads[url] else {
            
            if FileStorageManager.shared.uncachedFileExists(for: url) ||
                FileStorageManager.shared.videoExists(for: url) ||
                FileStorageManager.shared.imageExists(for: url) {
                return .finished
            } else {
                return .none
            }
        }
        return download.downloadModel.downloadState
    }
    
    internal func getDownloadProgress(for url: URL) -> Float? {
        guard let download = activeDownloads[url] else {
            return nil
        }
        return download.progress
    }
    
    internal func exchangeDownloadModel(newModel: DownloadModelRepresentable) {
        
        guard let currentlyActiveDownload = activeDownloads[newModel.sourceURL] else {
            fatalError("Attempting to exchange non-existen download model. This download task either does not exist or recently finished")
        }
        
        // Update delegate
        if let nonNullDelegate = newModel.delegate {
            currentlyActiveDownload.downloadModel.delegate = nonNullDelegate
        }
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Exchanging GenericCellModel with new model containing delegate: \(String(describing: newModel.delegate)). url: \(newModel.sourceURL)")
        
        newModel.update(downloadState: currentlyActiveDownload.downloadModel.downloadState)
    }
}




// MARK: - URLSessionDownloadDelegate

extension DownloadTaskManager: URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        guard let sourceURL = downloadTask.originalRequest?.url else {
            return
        }
        
        guard let httpResponse = downloadTask.response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error after download task completion. Incorrect response code")
            threadUnsafeActiveDownloads[sourceURL] = nil
            return
        }
        
        guard let download = activeDownloads[sourceURL] else {
            return
        }
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - finished download for url: \(sourceURL)")
        
        threadUnsafeActiveDownloads[sourceURL] = nil
        
        moveToIntermediateTemporaryFile(originalTemporaryURL: location, download: download)
    }
    
    private func moveToIntermediateTemporaryFile(originalTemporaryURL: URL, download: DownloadTaskRequest) {
        do {
            let intermediateTemporaryFileURL = try FileStorageManager.shared.moveToIntermediateTemporaryURL(originalTemporaryURL: originalTemporaryURL, sourceURL: download.downloadModel.sourceURL)
            
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Moved to intermediate temporary file url: \(intermediateTemporaryFileURL)")
            
            download.downloadModel.update(downloadState: .finished)
            
            // Notify delegate
            download.downloadModel.delegate?.cachable(download, didFinishDownloadingTo: intermediateTemporaryFileURL)
            
        } catch let error {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Could not copy file to disk: \(error)")
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


