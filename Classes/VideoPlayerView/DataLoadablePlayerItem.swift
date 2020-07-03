//
//  DataLoadablePlayerItem.swift
//  Pods
//
//  Created by Chrishon Wyllie on 6/26/20.
//

import AVFoundation

class DataLoadablePlayerItem: AVPlayerItem {
    
    private var mediaData: Data
    private var mediaDataMimeType: String
    private var pendingRequests = Set<AVAssetResourceLoadingRequest>()
    
    
    init(data: Data, mimeType: String, fileExtension: String) {
        
        // Fake URL forces AVAssetResourceLoaderDelegate to fill in video info
        // from the data argument
        let cachableAVPlayerItemScheme = "cachableAVPlayerItemScheme"
        let fakeURLString = cachableAVPlayerItemScheme + "://whatever/file.\(fileExtension)"
        guard let fakeUrl = URL(string: fakeURLString) else {
            fatalError("internal inconsistency")
        }
        
        self.mediaData = data
        self.mediaDataMimeType = mimeType
        
        
        let asset = AVURLAsset(url: fakeUrl)
        
        let assetKeys: [String] = [URLVideoPlayerView.LoadableAssetKeys.playable, .hasProtectedContent].map { $0.rawValue }
        super.init(asset: asset, automaticallyLoadedAssetKeys: assetKeys)
        asset.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - AVAssetResourceLoaderDelegate
extension DataLoadablePlayerItem: AVAssetResourceLoaderDelegate {
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        pendingRequests.insert(loadingRequest)
        processPendingRequests()
        return true
        
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        pendingRequests.remove(loadingRequest)
    }
    
    
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
        contentInformationRequest?.contentType = mediaDataMimeType
        contentInformationRequest?.contentLength = Int64(mediaData.count)
        contentInformationRequest?.isByteRangeAccessSupported = true
    }
    
    private func haveEnoughDataToFulfillRequest(_ dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
        
        let requestedOffset = Int(dataRequest.requestedOffset)
        let requestedLength = dataRequest.requestedLength
        let currentOffset = Int(dataRequest.currentOffset)
        
        guard mediaData.count > currentOffset else {
            // Don't have any data at all for this request.
            return false
        }
        
        let bytesToRespond = min(mediaData.count - currentOffset, requestedLength)
        let dataToRespond = mediaData.subdata(in: Range(uncheckedBounds: (currentOffset, currentOffset + bytesToRespond)))
        dataRequest.respond(with: dataToRespond)
        
        return mediaData.count >= requestedLength + requestedOffset
        
    }
}
