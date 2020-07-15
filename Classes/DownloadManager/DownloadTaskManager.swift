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
            strongSelf.cancelDownload(forSourceURL: sourceURL)
        }
    }
    
    internal func pauseAllDownloads() {
        performActionOnAllCurrentDownloadTasks { [weak self] (downloadTask) in
            guard let strongSelf = self else { return }
            guard let sourceURL = downloadTask.originalRequest?.url else {
                return
            }
            strongSelf.pauseDownload(forSourceURL: sourceURL)
        }
    }
    
    internal func resumeAllDownloads() {
        performActionOnAllCurrentDownloadTasks { [weak self] (downloadTask) in
            guard let strongSelf = self else { return }
            guard let sourceURL = downloadTask.originalRequest?.url else {
                return
            }
            strongSelf.resumeDownload(forSourceURL: sourceURL)
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
    
    internal func cancelDownload(forSourceURL sourceURL: URL) {
        guard let downloadTaskRequest = getDownloadTaskRequest(forSourceURL: sourceURL) else {
            return
        }
        downloadTaskRequest.task?.cancel()

        removeDownloadTaskRequest(forSourceURL: sourceURL)
    }
    internal func cancelDownload(downloadTaskRequest: DownloadTaskRequest) {
        cancelDownload(forSourceURL: downloadTaskRequest.sourceURL)
    }
    
    internal func pauseDownload(forSourceURL sourceURL: URL) {
        guard let downloadTaskRequest = getDownloadTaskRequest(forSourceURL: sourceURL) else {
            return
        }
        
        guard downloadTaskRequest.downloadState == .downloading else {
            return
        }
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - pausing download for url: \(sourceURL) - local file name: \(sourceURL.localUniqueFileName())")
        
        downloadTaskRequest.task?.cancel(byProducingResumeData: { [weak self] resumeDataOrNil in
            guard let resumeData = resumeDataOrNil else {
                return
            }
            downloadTaskRequest.storeResumableData(resumeData)
            downloadTaskRequest.update(downloadState: .paused)
            self?.save(downloadTaskRequest: downloadTaskRequest)
        })
    }
    internal func pauseDownload(downloadTaskRequest: DownloadTaskRequest) {
        pauseDownload(forSourceURL: downloadTaskRequest.sourceURL)
    }
    
    internal func resumeDownload(forSourceURL sourceURL: URL) {
        guard let downloadTaskRequest = getDownloadTaskRequest(forSourceURL: sourceURL) else {
            return
        }
        
        guard downloadTaskRequest.task?.state != .running else {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Download for url: \(sourceURL) is already running. Will perform no further action")
            return
        }
        
        if let resumeData = downloadTaskRequest.resumeData {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - resuming download for url from resume data: \(sourceURL)")
            let resumableDownloadTask = downloadsSession.downloadTask(withResumeData: resumeData)
            downloadTaskRequest.prepareForDownload(task: resumableDownloadTask)
        } else {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - resuming download for url (from scratch): \(sourceURL)")
            let newDownloadTask = downloadsSession.downloadTask(with: sourceURL)
            downloadTaskRequest.prepareForDownload(task: newDownloadTask)
        }
             
        downloadTaskRequest.task?.resume()
        downloadTaskRequest.update(downloadState: .downloading)
        
        save(downloadTaskRequest: downloadTaskRequest)
    }
    internal func resumeDownload(downloadTaskRequest: DownloadTaskRequest) {
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - using new download: \(String(describing: downloadTaskRequest.delegate))")
        mergeExistingDownloadTask(with: downloadTaskRequest)
        resumeDownload(forSourceURL: downloadTaskRequest.sourceURL)
    }
    
    internal func startDownload(downloadTaskRequest: DownloadTaskRequest) {
        if let existingDownloadTaskRequest = getDownloadTaskRequest(forSourceURL: downloadTaskRequest.sourceURL) {
            
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Attempted to start a download for url: \(downloadTaskRequest.sourceURL), but an active download already exists: \(existingDownloadTaskRequest). Will resume if not already running")
            
            guard existingDownloadTaskRequest.task?.state != .running else {
                DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Download for url: \(downloadTaskRequest.sourceURL) is already running. Will perform no further action")
                mergeExistingDownloadTask(with: downloadTaskRequest)
                return
            }
            
            resumeDownload(downloadTaskRequest: downloadTaskRequest)
            
        } else {
            beginFresh(downloadTaskRequest: downloadTaskRequest)
        }
    }

    private func beginFresh(downloadTaskRequest: DownloadTaskRequest) {
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - starting download for url: \(downloadTaskRequest.sourceURL) - local file name: \(downloadTaskRequest.sourceURL.localUniqueFileName())")
        
        // 1
        // 2
        let newDownloadTask = downloadsSession.downloadTask(with: downloadTaskRequest.sourceURL)
        downloadTaskRequest.prepareForDownload(task: newDownloadTask)
        // 3
        downloadTaskRequest.task?.resume()
        // 4
        downloadTaskRequest.update(downloadState: .downloading)
        // 5
        save(downloadTaskRequest: downloadTaskRequest)
        
//        MediaPendingOperations.shared.startDownload(for: model)
    }
}






// MARK: - Utility

extension DownloadTaskManager {
    
    internal func downloadState(forSourceURL sourceURL: URL) -> DownloadTaskState {
        guard let downloadTaskRequest = getDownloadTaskRequest(forSourceURL: sourceURL) else {
            
            if FileStorageManager.shared.uncachedFileExists(for: sourceURL) ||
                FileStorageManager.shared.videoExists(for: sourceURL) ||
                FileStorageManager.shared.imageExists(for: sourceURL) {
                return .finished
            } else {
                return .none
            }
        }
        return downloadTaskRequest.downloadState
    }
    
    internal func getDownloadProgress(forSourceURL sourceURL: URL) -> Float? {
        guard let downloadTaskRequest = getDownloadTaskRequest(forSourceURL: sourceURL) else {
            return nil
        }
        return downloadTaskRequest.progress
    }
    
    internal func mergeExistingDownloadTask(with newDownloadTask: DownloadTaskRequest) {
        
        guard let existingDownloadTaskRequest = getDownloadTaskRequest(forSourceURL: newDownloadTask.sourceURL) else {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error attempting to exchange non-existent download model for url: \(newDownloadTask.sourceURL). This download task either does not exist or recently finished. Active downloads: \(activeDownloads)")
            return
        }
        
        if existingDownloadTaskRequest.delegate != nil {
            // No reason to exchange
            return
        }
        
        // Update delegate
        if let nonNullDelegate = newDownloadTask.delegate {
            existingDownloadTaskRequest.delegate = nonNullDelegate
        }
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Exchanging GenericCellModel with new model containing delegate: \(String(describing: newDownloadTask.delegate)). url: \(newDownloadTask.sourceURL)")
        
        newDownloadTask.update(downloadState: existingDownloadTaskRequest.downloadState)
    }
    
    private func getDownloadTaskRequest(forSourceURL sourceURL: URL) -> DownloadTaskRequest? {
        return concurrentQueue.sync { [weak self] in
            self?.activeDownloads[sourceURL]
        }
    }

    private func save(downloadTaskRequest: DownloadTaskRequest) {
        concurrentQueue.async(flags: .barrier) { [weak self] in
            self?.activeDownloads[downloadTaskRequest.sourceURL] = downloadTaskRequest
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
        
        guard let downloadTaskRequest = getDownloadTaskRequest(forSourceURL: sourceURL) else {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - No download exists for url: \(sourceURL)")
            return
        }
        
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - finished download for url: \(sourceURL) - local file name: \(sourceURL.localUniqueFileName()). DownloadTask: \(downloadTask). Temporary file location: \(location)")
        
        removeDownloadTaskRequest(forSourceURL: sourceURL)
        
        moveToIntermediateTemporaryFile(originalTemporaryURL: location, downloadTaskRequest: downloadTaskRequest)
    }
    
    private func moveToIntermediateTemporaryFile(originalTemporaryURL: URL, downloadTaskRequest: DownloadTaskRequest) {
        do {
            let intermediateTemporaryFileURL = try FileStorageManager.shared.moveToIntermediateTemporaryURL(originalTemporaryURL: originalTemporaryURL, sourceURL: downloadTaskRequest.sourceURL)
            
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Moved to intermediate temporary file url: \(intermediateTemporaryFileURL)")
            
            downloadTaskRequest.update(downloadState: .finished)
            
            // Notify delegate
            downloadTaskRequest.delegate?.cachable(downloadTaskRequest, didFinishDownloadingTo: intermediateTemporaryFileURL)
            
        } catch let error {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error moving downloaded file to temporary file url: \(error)")
            downloadTaskRequest.delegate?.cachable(downloadTaskRequest, downloadFailedWith: error)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        
        guard let sourceURL = downloadTask.originalRequest?.url else {
            return
        }
        
        guard let downloadTaskRequest = getDownloadTaskRequest(forSourceURL: sourceURL) else {
            return
        }
        
        let (downloadProgress, humanReadableDownloadProgress) = Utility.shared.getDownloadProgress(totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        
        downloadTaskRequest.setProgress(downloadProgress)
        
        // Notify delegate
        if downloadTaskRequest.delegate == nil {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - delegate nil for download object: \(String(describing: downloadTaskRequest.delegate))")
        }
        downloadTaskRequest.delegate?.cachable(downloadTaskRequest, downloadProgress: downloadProgress, humanReadableProgress: humanReadableDownloadProgress)
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
            
            guard let downloadTaskRequest = getDownloadTaskRequest(forSourceURL: sourceURL) else {
                return
            }
            
            downloadTaskRequest.storeResumableData(resumeData)
            //
            downloadTaskRequest.update(downloadState: .paused)
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
