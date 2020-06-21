//
//  ResourceLoaderDelegate.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/28/19.
//

import AVFoundation

internal class ResourceLoaderDelegate: NSObject, URLSessionDelegate {
    
    // MARK: - Variables
   
    public private(set) var session: URLSession?
    public private(set) var initialURL: URL?
    public private(set) var isPlayingFromData = false
    
    private var response: URLResponse?
    
    fileprivate var mimeType: String? // is required when playing from Data
    fileprivate var mediaData: Data?
    fileprivate var pendingRequests = Set<AVAssetResourceLoadingRequest>()
    
    private var cachePolicy: MultimediaCachePolicy = .allow
    
    public weak var delegate: MediaResourceLoaderDelegate?
    
    
    
    
    
    
    
    // MARK: - Initializers
    
    convenience init(url: URL, cachePolicy: MultimediaCachePolicy = .allow) {
        self.init(cachePolicy: cachePolicy)
        self.initialURL = url
    }
    
    init(cachePolicy: MultimediaCachePolicy = .allow) {
        super.init()
        self.cachePolicy = cachePolicy
    }
    
    
    
    
    
    
    // MARK: - Public Functions
    
    public func startDataRequest(with url: URL) {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        session?.dataTask(with: url).resume()
    }
    
    public func setMediaData(_ data: Data, mimeType: String) {
        self.mediaData = data
        self.isPlayingFromData = true
        self.mimeType = mimeType
    }
    
    deinit {
        session?.invalidateAndCancel()
    }
    
}



// MARK: - URLSessionDataDelegate

extension ResourceLoaderDelegate: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        mediaData?.append(data)
        processPendingRequests()
        
        guard let mediaData = mediaData else {
            return
        }
        
        // TODO
        // Move this function to utility
        let totalBytesWritten: Int64 = Int64(mediaData.count)
        let totalBytesExpectedToWrite: Int64 = dataTask.countOfBytesExpectedToReceive
        
        let (downloadProgress, humanReadableDownloadProgress) = Utility.shared.getDownloadProgress(totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        
        delegate?.resourceLoader(self, downloadProgress: CGFloat(downloadProgress), humanReadableProgress: humanReadableDownloadProgress)
        
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        completionHandler(Foundation.URLSession.ResponseDisposition.allow)
        mediaData = Data()
        self.response = response
        processPendingRequests()
    }
    
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        guard let mediaData = mediaData else {
            return
        }
        
        if let errorUnwrapped = error {
            delegate?.resourceLoader(self, downloadFailedWith: errorUnwrapped)
        } else {
            processPendingRequests()
            
            guard let sourceURL = task.originalRequest?.url else {
                return
            }
            
            let originalVideoData = OriginalVideoData(videoData: mediaData,
                                                      originalURLMimeType: sourceURL.mimeType(),
                                                      originalURLFileExtension: sourceURL.pathExtension)
            if self.cachePolicy == .allow {
                Celestial.shared.store(video: originalVideoData, with: sourceURL.absoluteString)
            }
            
            delegate?.resourceLoader(self, didFinishDownloading: originalVideoData)
        }
    }
    
}


// MARK: - Private utility functions

extension ResourceLoaderDelegate {
    
    fileprivate func processPendingRequests() {
        
        // get all fullfilled requests
        let requestsFulfilled = Set<AVAssetResourceLoadingRequest>(pendingRequests.compactMap {
            self.fillInContentInformationRequest($0.contentInformationRequest)
            if self.haveEnoughDataToFulfillRequest($0.dataRequest!) {
                $0.finishLoading()
                return $0
            }
            return nil
        })
    
        // remove fulfilled requests from pending requests
        _ = requestsFulfilled.map { self.pendingRequests.remove($0) }

    }
    
    private func fillInContentInformationRequest(_ contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {
        
        guard let mediaData = mediaData else {
            return
        }
        
        // if we play from Data we make no url requests, therefore we have no responses, so we need to fill in contentInformationRequest manually
        if isPlayingFromData {
            contentInformationRequest?.contentType = self.mimeType
            contentInformationRequest?.contentLength = Int64(mediaData.count)
            contentInformationRequest?.isByteRangeAccessSupported = true
            return
        }
        
        guard let responseUnwrapped = response else {
            // have no response from the server yet
            return
        }
        
        contentInformationRequest?.contentType = responseUnwrapped.mimeType
        contentInformationRequest?.contentLength = responseUnwrapped.expectedContentLength
        contentInformationRequest?.isByteRangeAccessSupported = true
        
    }
    
    private func haveEnoughDataToFulfillRequest(_ dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
        
        let requestedOffset = Int(dataRequest.requestedOffset)
        let requestedLength = dataRequest.requestedLength
        let currentOffset = Int(dataRequest.currentOffset)
        
        guard
            let mediaDataUnwrapped = mediaData,
            mediaDataUnwrapped.count > currentOffset
            else {
            // Don't have any data at all for this request.
            return false
        }
        
        let bytesToRespond = min(mediaDataUnwrapped.count - currentOffset, requestedLength)
        let dataToRespond = mediaDataUnwrapped.subdata(in: Range(uncheckedBounds: (currentOffset, currentOffset + bytesToRespond)))
        dataRequest.respond(with: dataToRespond)
        
        return mediaDataUnwrapped.count >= requestedLength + requestedOffset
        
    }
}


















// MARK: - AVURLAssetResourceLoader

internal class AVURLAssetResourceLoader: ResourceLoaderDelegate, AVAssetResourceLoaderDelegate {
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        if isPlayingFromData {
            
            // Nothing to load.
            print("ResourceLoaderDelegate - Nothing to load")
            
        } else if session == nil {
            
            // If we're playing from a url, we need to download the file.
            // We start loading the file on first request only.
            guard let initialURL = initialURL else {
                fatalError("internal inconsistency")
            }

            startDataRequest(with: initialURL)
            
        }
        
        pendingRequests.insert(loadingRequest)
        processPendingRequests()
        return true
        
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        pendingRequests.remove(loadingRequest)
    }
    
}
