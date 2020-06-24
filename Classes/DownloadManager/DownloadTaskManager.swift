//
//  DownloadTaskManager.swift
//  Celestial
//
//  Created by Chrishon Wyllie on 6/22/20.
//

import Foundation

protocol DownloadTaskManagerProtocol {
    var activeDownloads: [URL: DownloadTaskRequest] { get }
    var downloadsSession: URLSession { get }
    
    func cancelDownload(model: DownloadModelRepresentable)
    
    func pauseDownload(model: DownloadModelRepresentable)
    
    func resumeDownload(model: DownloadModelRepresentable)
    
    func startDownload(model: DownloadModelRepresentable)
}

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
    
    
    
    internal func downloadIsInProgress(for url: URL) -> Bool {
        guard let download = activeDownloads[url] else {
            return false
        }
        return download.downloadObject.downloadState == .downloading
    }
    
    internal func downloadIsPaused(for url: URL) -> Bool {
        guard let download = activeDownloads[url] else {
            return false
        }
        return download.downloadObject.downloadState == .paused
    }
    
    
    
    
    
    internal func getDownloadProgress(for url: URL) -> Float? {
        guard let download = activeDownloads[url] else {
            return nil
        }
        return download.progress
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
        
        guard download.downloadObject.downloadState == .downloading else {
            return
        }
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - pausing download for url: \(url)")
        
        download.task?.cancel(byProducingResumeData: { data in
            download.resumeData = data
        })

        download.downloadObject.update(downloadState: .paused)
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
        download.downloadObject.update(downloadState: .downloading)
    }
    internal func resumeDownload(model: DownloadModelRepresentable) {
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - using new download: \(String(describing: model.delegate))")
        activeDownloads[model.sourceURL]?.downloadObject.delegate = model.delegate
        resumeDownload(for: model.sourceURL)
    }
    
    internal func startDownload(model: DownloadModelRepresentable) {
        if let _ = activeDownloads[model.sourceURL] {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - currently active download")
            resumeDownload(model: model)
            return
        }
        beginFreshDownload(model: model)
    }
    
    private func beginFreshDownload(model: DownloadModelRepresentable) {
        DebugLogger.shared.addDebugMessage("starting download for url: \(model.sourceURL)")
        // 1
        let download = DownloadTaskRequest(downloadObject: model)
        // 2
        download.task = downloadsSession.downloadTask(with: model.sourceURL)
        // 3
        download.task?.resume()
        // 4
        download.downloadObject.update(downloadState: .downloading)
        // 5
        activeDownloads[model.sourceURL] = download
    }
    
}





// MARK: - URLSessionDownloadDelegate

extension DownloadTaskManager: URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // 1
        guard let sourceURL = downloadTask.originalRequest?.url else {
            return
        }
      
        guard let download = activeDownloads[sourceURL] else {
            return
        }
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - finished download for url: \(sourceURL)")
        activeDownloads[sourceURL] = nil
      
        // 3
        moveToIntermediateTemporaryFile(originalTemporaryURL: location, download: download)
    }
    
    private func moveToIntermediateTemporaryFile(originalTemporaryURL: URL, download: DownloadTaskRequest) {
        do {
            let temporaryFileURL = try FileStorageManager.shared.moveToIntermediateTemporaryURL(originalTemporaryURL: originalTemporaryURL)
            
            download.downloadObject.update(downloadState: .finished)
            
            // Notify delegate
            download.downloadObject.delegate?.cachable(download, didFinishDownloadingTo: temporaryFileURL)
            
        } catch let error {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Could not copy file to disk: \(error.localizedDescription)")
            download.downloadObject.delegate?.cachable(download, downloadFailedWith: error)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        // 1
        guard let sourceURL = downloadTask.originalRequest?.url else {
            return
        }
        
        guard let download = activeDownloads[sourceURL] else {
            return
        }
        
        // 2
        let (downloadProgress, humanReadableDownloadProgress) = Utility.shared.getDownloadProgress(totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        
        download.progress = downloadProgress
        
        // 3
        // Notify delegate
        if download.downloadObject.delegate == nil {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - delegate nil for download object: \(download.downloadObject)")
        }
        download.downloadObject.delegate?.cachable(download, downloadProgress: downloadProgress, humanReadableProgress: humanReadableDownloadProgress)
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
