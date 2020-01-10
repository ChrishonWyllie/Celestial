//
//  URLImageView.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import UIKit

/// Subclass of UIImageView which can download and display an image from an external URL,
/// then cache it for future use if desired.
/// This is used together with the Celestial cache to prevent needless downloading of the same images.
open class URLImageView: UIImageView {
    
    // MARK: - Variables
    
    private weak var delegate: URLImageViewDelegate?
    
    public private(set) var cachePolicy: MultimediaCachePolicy = .allow
    
    public private(set) var urlString: String?
    
    private var defaultImage: UIImage?
    
    private var downloadTaskHandler: DownloadTaskHandler<UIImage>?
    
    // Wait for layoutSubviews to set this property
    private var size: CGSize?
    
    
    
    
    
    // MARK: - Initializers
    
    /// - Parameter urlString: The URL.absoluteString of the image you would like to download and display (NOTE: You may download this image sometime after instantiation by using:
    /// ````
    ///     loadImageFrom(urlString: String)
    /// ````
    /// - Parameter delegate: `URLImageViewDelegate` for useful delegation functions such as knowing when download has completed, or its current progress.
    /// - Parameter cachePolicy: `MultimediaCachePolicy` for determining whether the image should be cached upon completion of its download.
    /// - Parameter defaultImage: `UIImage` a default image that will be used if download fails.
    public convenience init(urlString: String, delegate: URLImageViewDelegate?, cachePolicy: MultimediaCachePolicy = .allow, defaultImage: UIImage? = nil) {
        self.init(delegate: delegate, cachePolicy: cachePolicy, defaultImage: defaultImage)
        self.loadImageFrom(urlString: urlString)
    }
    
    public init(delegate: URLImageViewDelegate?, cachePolicy: MultimediaCachePolicy = .allow, defaultImage: UIImage? = nil) {
        super.init(frame: .zero)
        self.cachePolicy = cachePolicy
        self.delegate = delegate
        self.defaultImage = defaultImage
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.size = self.frame.size
    }
    
    
    
    // MARK: - Functions
    
    /// Downloads an image from an external URL string
    public func loadImageFrom(urlString: String) {
        
        self.image = nil
        
        //check cache for image first
        if let cachedImage = Celestial.shared.image(for: urlString) {
            self.image = cachedImage
            return
        }
        
        // Otherwise, fire off a new download
        
        performDownload(at: urlString)
        
    }
    
    public func loadImageFrom(urlString: String, progressHandler: (DownloadTaskProgressHandler?), completion: (() -> ())?, errorHandler: (DownloadTaskErrorHandler?)) {
        
        self.image = nil
        
        if let cachedImage = Celestial.shared.image(for: urlString) {
            self.image = cachedImage
            completion?()
            return
        } else {
            
            // Otherwise, fire off a new download
            
            // First, set up the download task handler
            
            downloadTaskHandler = DownloadTaskHandler<UIImage>()
            downloadTaskHandler?.completionHandler = { (downloadedImage) in
                DispatchQueue.main.async {
                    self.image = downloadedImage
                    completion?()
                }
            }
            downloadTaskHandler?.progressHandler = { (downloadProgress) in
                progressHandler?(downloadProgress)
            }
            downloadTaskHandler?.errorHandler = { (error) in
                errorHandler?(error)
            }
            
            // Then, perform the download
            
            performDownload(at: urlString)
        }
    }
    
    private func performDownload(at urlString: String) {
        
        // Store a reference to the urlString, so that we can save in Cache when download completes
        self.urlString = urlString
        
        let configuration = URLSessionConfiguration.default
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        let downloadTask = urlSession.downloadTask(with: url)
        downloadTask.resume()
    }
}







// MARK: -  URLSessionDownloadDelegate

extension URLImageView: URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        let percentage = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: .file)
        let humanReadablePercentage = String(format: "%.1f%% of %@", percentage * 100, totalSize)
        
        delegate?.urlImageView?(self, downloadProgress: percentage, humanReadableProgress: humanReadablePercentage)
        
        // This is only called if `loadImageFrom(urlString:, progressHandler:, completion:, errorHandler:)` was called.
        // In which case, this property will be non-nil
        downloadTaskHandler?.progressHandler?(percentage)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }
        fallbackOnDefaultImageIfExists()
        delegate?.urlImageView(self, downloadFailedWith: error)
        
        // This is only called if `loadImageFrom(urlString:, progressHandler:, completion:, errorHandler:)` was called.
        // In which case, this property will be non-nil
        downloadTaskHandler?.errorHandler?(error)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        // The location is only temporary. You need to read it or copy it to your container before
        // exiting this function. UIImage(contentsOfFile: ) seems to load the image lazily. NSData
        // does it right away.
        do {
            let data = try Data(contentsOf: location)
            if var downloadedImage = UIImage(data: data) {
                
                guard let urlString = self.urlString else { return }
                
                // Often, the downloaded image is high resolution, and thus very large
                // in both memory and pixel size.
                // Create a thumbnail that is the size of the URLImageView that downloaded
                // it (self).
                let thumbnailImageSize = self.size ?? UIScreen.main.bounds.size
                downloadedImage = downloadedImage.resize(size: thumbnailImageSize) ?? downloadedImage
                
                if cachePolicy == .allow {
                    Celestial.shared.store(image: downloadedImage, with: urlString)
                }
                
                if downloadTaskHandler != nil {
                    // This is only called if `loadImageFrom(urlString:, progressHandler:, completion:, errorHandler:)` was called.
                    // In which case, this property will be non-nil
                    downloadTaskHandler?.completionHandler?(downloadedImage)
                } else {
                    DispatchQueue.main.async {
                        self.image = downloadedImage
                    }
                    
                    delegate?.urlImageView(self, didFinishDownloading: downloadedImage)
                }
                
            }
        } catch let dataError {
            fallbackOnDefaultImageIfExists()
            delegate?.urlImageView(self, downloadFailedWith: dataError)
            
            // This is only called if `loadImageFrom(urlString:, progressHandler:, completion:, errorHandler:)` was called.
            // In which case, this property will be non-nil
            downloadTaskHandler?.errorHandler?(dataError)
        }
    }
    
    private func fallbackOnDefaultImageIfExists() {
        if let defaultImage = defaultImage {
            self.image = defaultImage
        }
    }
    
}
