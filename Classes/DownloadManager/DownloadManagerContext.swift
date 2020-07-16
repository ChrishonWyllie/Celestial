//
//  DownloadManagerContext.swift
//  Celestial
//
//  Created by Chrishon Wyllie on 7/15/20.
//

import Foundation

internal class DownloadManagerContext {
    
    private var activeDownloads: [URL : DownloadTaskRequest] = [:]
    private let userDefaults = UserDefaults.standard
    
    private let concurrentQueue = DispatchQueue(label: "com.chrishonwyllie.Celestial.DownloadTaskManager.downloadTaskQueue",
    attributes: .concurrent)
    
    
    
    internal func downloadTaskRequest(forSourceURL sourceURL: URL) -> DownloadTaskRequest? {
        concurrentQueue.sync { [weak self] in
            if let inMemoryDownload = self?.activeDownloads[sourceURL] {
                return inMemoryDownload
            } else if let storedDownload = self?.loadDownloadTaskFromStorage(withSourceURL: sourceURL) {
                activeDownloads[storedDownload.sourceURL] = storedDownload

                return storedDownload
            }

            return nil
        }
    }

    private func loadDownloadTaskFromStorage(withSourceURL sourceURL: URL) -> DownloadTaskRequest? {
        guard let encodedData = UserDefaults.standard.object(forKey: sourceURL.path) as? Data else {
            return nil
        }

        let downloadTask = try? JSONDecoder().decode(DownloadTaskRequest.self, from: encodedData)
        return downloadTask
    }

    internal func save(downloadTaskRequest: DownloadTaskRequest) {
        concurrentQueue.async(flags: .barrier) { [weak self] in
            self?.activeDownloads[downloadTaskRequest.sourceURL] = downloadTaskRequest
            
            let encodedData = try? JSONEncoder().encode(downloadTaskRequest)
            self?.userDefaults.set(encodedData, forKey: downloadTaskRequest.sourceURL.path)
        }
    }
    
    internal func removeDownloadTaskRequest(forSourceURL sourceURL: URL) {
        concurrentQueue.async(flags: .barrier) { [weak self] in
            self?.activeDownloads.removeValue(forKey: sourceURL)
            self?.userDefaults.removeObject(forKey: sourceURL.path)
        }
    }
}
