//
//  CachableAVPlayerItem.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/28/19.
//

import Foundation
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









public class CachableAVPlayerItem: AVPlayerItem {
    
    fileprivate let resourceLoaderDelegate = ResourceLoaderDelegate()
    public private(set) var url: URL
    fileprivate let initialScheme: String?
    fileprivate var customFileExtension: String?
    public private(set) var cachePolicy: MultimediaCachePolicy = .allow
    
    public private(set) weak var delegate: CachableAVPlayerItemDelegate?
    
    open func download() {
        if resourceLoaderDelegate.session == nil {
            resourceLoaderDelegate.startDataRequest(with: url)
        }
    }
    
    private let cachingPlayerItemScheme = "cachingPlayerItemScheme"
    
    /// Is used for playing remote files.
    convenience public init(url: URL, delegate: CachableAVPlayerItemDelegate?, cachePolicy: MultimediaCachePolicy = .allow) {
        self.init(url: url, customFileExtension: nil, delegate: delegate, cachePolicy: cachePolicy)
    }
    
    /// Override/append custom file extension to URL path.
    /// This is required for the player to work correctly with the intended file type.
    public init(url: URL, customFileExtension: String?, delegate: CachableAVPlayerItemDelegate?, cachePolicy: MultimediaCachePolicy = .allow) {
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let scheme = components.scheme,
            var urlWithCustomScheme = url.withScheme(cachingPlayerItemScheme) else {
            fatalError("Urls without a scheme are not supported")
        }
        
        self.url = url
        self.delegate = delegate
        self.cachePolicy = cachePolicy
        self.initialScheme = scheme
        
        if let ext = customFileExtension {
            urlWithCustomScheme.deletePathExtension()
            urlWithCustomScheme.appendPathExtension(ext)
            self.customFileExtension = ext
        }
        
        let asset = AVURLAsset(url: urlWithCustomScheme)
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        
        resourceLoaderDelegate.owner = self
        
        addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStalledHandler), name:NSNotification.Name.AVPlayerItemPlaybackStalled, object: self)
        
    }
    
    /// Is used for playing from Data.
    public init(data: Data, mimeType: String, fileExtension: String) {
        
        guard let fakeUrl = URL(string: cachingPlayerItemScheme + "://whatever/file.\(fileExtension)") else {
            fatalError("internal inconsistency")
        }
        
        self.url = fakeUrl
        self.initialScheme = nil
        
        resourceLoaderDelegate.mediaData = data
        resourceLoaderDelegate.playingFromData = true
        resourceLoaderDelegate.mimeType = mimeType
        
        let asset = AVURLAsset(url: fakeUrl)
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        resourceLoaderDelegate.owner = self
        
        addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStalledHandler), name:NSNotification.Name.AVPlayerItemPlaybackStalled, object: self)
        
    }
    
    // MARK: KVO
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        delegate?.playerItemReadyToPlay?(self)
    }
    
    // MARK: Notification hanlers
    
    @objc func playbackStalledHandler() {
        delegate?.playerItemPlaybackStalled?(self)
    }

    // MARK: -
    
    override init(asset: AVAsset, automaticallyLoadedAssetKeys: [String]?) {
        fatalError("not implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        removeObserver(self, forKeyPath: "status")
        resourceLoaderDelegate.session?.invalidateAndCancel()
    }
    
}
