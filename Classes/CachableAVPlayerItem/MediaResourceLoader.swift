//
//  MediaResourceLoader.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/28/19.
//

import AVFoundation

internal class MediaResourceLoader: NSObject, URLSessionDelegate {
    
    // MARK: - Variables
   
    public private(set) var session: URLSession?
    public private(set) var initialURL: URL?
    public private(set) var isPlayingFromData = false
    
    private var response: URLResponse?
    
    private var mediaDataMimeType: String? // is required when playing from Data
    private var mediaData: Data?
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
        initialURL = url
        loadResourceWithDataTask(url: url)
    }
    
    private func loadResourceWithDataTask(url: URL) {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        session?.dataTask(with: url).resume()
    }
    
    public func setMediaData(_ data: Data, mimeType: String) {
        self.mediaData = data
        self.isPlayingFromData = true
        self.mediaDataMimeType = mimeType
    }
    
    deinit {
        session?.invalidateAndCancel()
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    private func sendDownloadedFile(location: URL? = nil, error: Error? = nil) {
        if let error = error {
            sendError(error)
        } else if let temporaryFileLocation = location {
            do {
                let downloadedMediaData = try Data(contentsOf: temporaryFileLocation)
                
                delegate?.resourceLoader(self, didFinishDownloading: downloadedMediaData)

           } catch let dataError {

                delegate?.resourceLoader(self, downloadFailedWith: dataError)
            }
        } else if let mediaData = mediaData {
            processPendingRequests()

            delegate?.resourceLoader(self, didFinishDownloading: mediaData)
        }
    }
    
    private func sendProgress(totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {

        let (downloadProgress, humanReadableDownloadProgress) = Utility.shared.getDownloadProgress(totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)

        delegate?.resourceLoader(self, downloadProgress: CGFloat(downloadProgress), humanReadableProgress: humanReadableDownloadProgress)

    }
    
    private func sendError(_ error: Error?) {
        if let errorUnwrapped = error {
            delegate?.resourceLoader(self, downloadFailedWith: errorUnwrapped)
        }
    }
    
    func clear() {
        mediaData = nil
        session?.invalidateAndCancel()
        session = nil
    }
}



// MARK: - URLSessionDataDelegate

extension MediaResourceLoader: URLSessionDataDelegate {

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

        sendProgress(totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)

    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {

        completionHandler(Foundation.URLSession.ResponseDisposition.allow)
        mediaData = Data()
        self.response = response
        processPendingRequests()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        sendDownloadedFile(error: error)
    }
}








// MARK: - AVAssetResourceLoaderDelegate

extension MediaResourceLoader:  AVAssetResourceLoaderDelegate {
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        if isPlayingFromData {
            
            // Nothing to load.
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) -  Nothing to load")
            
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











// MARK: - Private utility functions

extension MediaResourceLoader {
    
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
        
        contentInformationRequest?.isByteRangeAccessSupported = true
        
        // if we play from Data we make no url requests, therefore we have no responses, so we need to fill in contentInformationRequest manually
        if isPlayingFromData {
            contentInformationRequest?.contentType = mediaDataMimeType
            contentInformationRequest?.contentLength = Int64(mediaData!.count)
            return
        }
        
        guard let responseUnwrapped = response else {
            // have no response from the server yet
            return
        }
        
        contentInformationRequest?.contentType = responseUnwrapped.mimeType
        contentInformationRequest?.contentLength = responseUnwrapped.expectedContentLength
        
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
