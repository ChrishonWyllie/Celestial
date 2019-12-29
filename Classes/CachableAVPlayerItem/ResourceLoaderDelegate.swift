//
//  ResourceLoaderDelegate.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/28/19.
//

import AVFoundation

internal class ResourceLoaderDelegate: NSObject, URLSessionDelegate {
    
    var playingFromData = false
    var mimeType: String? // is required when playing from Data
    var session: URLSession?
    var mediaData: Data?
    var response: URLResponse?
    var pendingRequests = Set<AVAssetResourceLoadingRequest>()
    weak var owner: CachableAVPlayerItem?
    
    
    
    public func startDataRequest(with url: URL) {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        session?.dataTask(with: url).resume()
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
        owner?.delegate?.playerItem?(owner!, didDownloadBytesSoFar: mediaData!.count, outOf: Int(dataTask.countOfBytesExpectedToReceive))
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(Foundation.URLSession.ResponseDisposition.allow)
        mediaData = Data()
        self.response = response
        processPendingRequests()
    }
    
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let errorUnwrapped = error {
            owner?.delegate?.playerItem?(owner!, downloadingFailedWith: errorUnwrapped)
            return
        }
        processPendingRequests()
        owner?.delegate?.playerItem?(owner!, didFinishDownloadingData: mediaData!)
    }
    
}


// MARK: - AVAssetResourceLoaderDelegate

extension ResourceLoaderDelegate: AVAssetResourceLoaderDelegate {
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        if playingFromData {
            
            // Nothing to load.
            
        } else if session == nil {
            
            // If we're playing from a url, we need to download the file.
            // We start loading the file on first request only.
            guard let initialUrl = owner?.url else {
                fatalError("internal inconsistency")
            }

            startDataRequest(with: initialUrl)
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

extension ResourceLoaderDelegate {
    
    private func processPendingRequests() {
        
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
        
        // if we play from Data we make no url requests, therefore we have no responses, so we need to fill in contentInformationRequest manually
        if playingFromData {
            contentInformationRequest?.contentType = self.mimeType
            contentInformationRequest?.contentLength = Int64(mediaData!.count)
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
        
        guard let songDataUnwrapped = mediaData,
            songDataUnwrapped.count > currentOffset else {
            // Don't have any data at all for this request.
            return false
        }
        
        let bytesToRespond = min(songDataUnwrapped.count - currentOffset, requestedLength)
        let dataToRespond = songDataUnwrapped.subdata(in: Range(uncheckedBounds: (currentOffset, currentOffset + bytesToRespond)))
        dataRequest.respond(with: dataToRespond)
        
        return songDataUnwrapped.count >= requestedLength + requestedOffset
        
    }
}
