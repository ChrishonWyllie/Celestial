//
//  DownloadTaskManager.swift
//  Celestial
//
//  Created by Chrishon Wyllie on 6/22/20.
//

import Foundation

/// Singleton for managing all downloads of resources from external URLs
class DownloadTaskManager: NSObject, DownloadTaskManagerProtocol {
    
    internal static let shared = DownloadTaskManager()
    
    internal private(set) var activeDownloads: [URL : DownloadTaskRequest] = [:]
    
    private let concurrentQueue = DispatchQueue(label: "com.chrishonwyllie.Celestial.DownloadTaskManager.downloadTaskQueue",
                                                attributes: .concurrent)
    
    internal static let backgroundDownloadSessionIdentifier: String = "com.chrishonwyllie.Celestial.DownloadTaskManager.URLSession.background.identifier"
    private(set) lazy var downloadsSession: URLSession = {
        let identifier = DownloadTaskManager.backgroundDownloadSessionIdentifier
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    
    
    
    
    
    
    
    
    
    
    private override init() {
        super.init()
    }
    
    
    
    
    
    
    
    
    internal func cancelAllDownloads() {
        performActionOnAllCurrentDownloadTasks { [weak self] (downloadTask) in
            guard let strongSelf = self else { return }
            guard let sourceURL = downloadTask.originalRequest?.url else {
                return
            }
            strongSelf.cancelDownload(for: sourceURL)
        }
    }
    
    internal func pauseAllDownloads() {
        performActionOnAllCurrentDownloadTasks { [weak self] (downloadTask) in
            guard let strongSelf = self else { return }
            guard let sourceURL = downloadTask.originalRequest?.url else {
                return
            }
            strongSelf.pauseDownload(for: sourceURL)
        }
    }
    
    internal func resumeAllDownloads() {
        performActionOnAllCurrentDownloadTasks { [weak self] (downloadTask) in
            guard let strongSelf = self else { return }
            guard let sourceURL = downloadTask.originalRequest?.url else {
                return
            }
            strongSelf.resumeDownload(for: sourceURL)
        }
    }
    
    private func performActionOnAllCurrentDownloadTasks(completion: @escaping (URLSessionDownloadTask) -> ()) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.downloadsSession.getTasksWithCompletionHandler { (dataTasks: [URLSessionDataTask], uploadTasks: [URLSessionUploadTask], downloadTasks:  [URLSessionDownloadTask]) in
                
                if downloadTasks.count == 0 {
                    return
                }
                
                DebugLogger.shared.addDebugMessage("\(String(describing: type(of: strongSelf))) - Performing action on \(downloadTasks.count) downloadTasks")
                
                for task in downloadTasks {
                    completion(task)
                }
            }
        }
    }
    
    internal func cancelDownload(for url: URL) {
        guard let download = downloadTaskRequest(forSourceURL: url) else {
            return
        }
        download.task?.cancel()

        removeDownloadTaskRequest(forSourceURL: url)
    }
    internal func cancelDownload(model: DownloadModelRepresentable) {
        cancelDownload(for: model.sourceURL)
    }
    
    internal func pauseDownload(for url: URL) {
        guard let download = downloadTaskRequest(forSourceURL: url) else {
            return
        }
        
        guard download.downloadModel.downloadState == .downloading else {
            return
        }
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - pausing download for url: \(url) - local file name: \(url.localUniqueFileName())")
        
        download.task?.cancel(byProducingResumeData: { [weak self] resumeDataOrNil in
            guard let resumeData = resumeDataOrNil else {
                return
            }
            download.resumeData = resumeData
            download.downloadModel.update(downloadState: .paused)
            self?.set(downloadTaskRequest: download, forSourceURL: url)
        })
    }
    internal func pauseDownload(model: DownloadModelRepresentable) {
        pauseDownload(for: model.sourceURL)
    }
    
    internal func resumeDownload(for url: URL) {
        guard let download = downloadTaskRequest(forSourceURL: url) else {
            return
        }
        
        guard download.task?.state != .running else {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Download for url: \(url) is already running. Will perform no further action")
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
        
        set(downloadTaskRequest: download, forSourceURL: url)
    }
    internal func resumeDownload(model: DownloadModelRepresentable) {
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - using new download: \(String(describing: model.delegate))")
        exchangeDownloadModel(newModel: model)
        resumeDownload(for: model.sourceURL)
    }
    
    internal func startDownload(model: DownloadModelRepresentable) {
        if let download = downloadTaskRequest(forSourceURL: model.sourceURL) {
            
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Attempted to start a download for url: \(model.sourceURL), but an active download already exists: \(download). Will resume if not already running")
            
            guard download.task?.state != .running else {
                DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Download for url: \(model.sourceURL) is already running. Will perform no further action")
                exchangeDownloadModel(newModel: model)
                return
            }
            
            resumeDownload(model: model)
            
        } else {
            beginFreshDownload(model: model)
        }
    }
    
    private func beginFreshDownload(model: DownloadModelRepresentable) {
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - starting download for url: \(model.sourceURL) - local file name: \(model.sourceURL.localUniqueFileName())")
        
        // 1
        let download = DownloadTaskRequest(downloadModel: model)
        // 2
        download.task = downloadsSession.downloadTask(with: model.sourceURL)
        // 3
        download.task?.resume()
        // 4
        download.downloadModel.update(downloadState: .downloading)
        // 5
        set(downloadTaskRequest: download, forSourceURL: model.sourceURL)
        
//        MediaPendingOperations.shared.startDownload(for: model)
    }
}






// MARK: - Utility

extension DownloadTaskManager {
    
    internal func downloadState(for url: URL) -> DownloadTaskState {
        guard let download = downloadTaskRequest(forSourceURL: url) else {
            
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
        guard let download = downloadTaskRequest(forSourceURL: url) else {
            return nil
        }
        return download.progress
    }
    
    internal func exchangeDownloadModel(newModel: DownloadModelRepresentable) {
        
        guard let currentlyActiveDownload = downloadTaskRequest(forSourceURL: newModel.sourceURL) else {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error attempting to exchange non-existent download model for url: \(newModel.sourceURL). This download task either does not exist or recently finished. Active downloads: \(activeDownloads)")
            return
        }
        
        if currentlyActiveDownload.downloadModel.delegate != nil {
            // No reason to exchange
            return
        }
        
        // Update delegate
        if let nonNullDelegate = newModel.delegate {
            currentlyActiveDownload.downloadModel.delegate = nonNullDelegate
        }
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Exchanging GenericCellModel with new model containing delegate: \(String(describing: newModel.delegate)). url: \(newModel.sourceURL)")
        
        newModel.update(downloadState: currentlyActiveDownload.downloadModel.downloadState)
    }
    
    private func downloadTaskRequest(forSourceURL sourceURL: URL) -> DownloadTaskRequest? {
        return concurrentQueue.sync { [weak self] in
            self?.activeDownloads[sourceURL]
        }
    }

    private func set(downloadTaskRequest: DownloadTaskRequest, forSourceURL sourceURL: URL) {
        concurrentQueue.async(flags: .barrier) { [weak self] in
            self?.activeDownloads[sourceURL] = downloadTaskRequest
        }
    }
    
    private func removeDownloadTaskRequest(forSourceURL sourceURL: URL) {
        concurrentQueue.async(flags: .barrier) { [weak self] in
            self?.activeDownloads.removeValue(forKey: sourceURL)
        }
    }
}













// MARK: - URLSessionDownloadDelegate

extension DownloadTaskManager: URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        guard FileManager.default.fileExists(atPath: location.path) else {
            return
        }
        
        guard let sourceURL = downloadTask.originalRequest?.url else {
            return
        }
        
        let rangeOfNonErrorStatusCodes = 200...299
        guard let httpResponse = downloadTask.response as? HTTPURLResponse,
            (rangeOfNonErrorStatusCodes).contains(httpResponse.statusCode) else {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error after download task completion. Incorrect response code")
            
            removeDownloadTaskRequest(forSourceURL: sourceURL)
            return
        }
        
        guard let download = downloadTaskRequest(forSourceURL: sourceURL) else {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - No download exists for url: \(sourceURL)")
            return
        }
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - finished download for url: \(sourceURL) - local file name: \(sourceURL.localUniqueFileName()). DownloadTask: \(download). Temporary file location: \(location)")
        
        removeDownloadTaskRequest(forSourceURL: sourceURL)
        
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
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error moving downloaded file to temporary file url: \(error)")
            download.downloadModel.delegate?.cachable(download, downloadFailedWith: error)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        
        guard let sourceURL = downloadTask.originalRequest?.url else {
            return
        }
        
        guard let download = downloadTaskRequest(forSourceURL: sourceURL) else {
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
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        guard let error = error else {
            if let sourceURL = task.originalRequest?.url {
                removeDownloadTaskRequest(forSourceURL: sourceURL)
            }
            return
        }
        
        let userInfo = (error as NSError).userInfo
        
        if let resumeData = userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
            
            // If cannot retrieve download for this sourceURL,
            // perhaps store the resume data in documents directory
            // until a new download is created with this sourceURL?
            guard let sourceURL = task.originalRequest?.url else {
                return
            }
            
            guard let download = downloadTaskRequest(forSourceURL: sourceURL) else {
                return
            }
            
            download.resumeData = resumeData
            //
            download.downloadModel.update(downloadState: .paused)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Resuming download")
    }
}












// MARK: - URLSessionDelegate

extension DownloadTaskManager: URLSessionDelegate {
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            Celestial.shared.completeBackgroundSession()
        }
    }
    
}
