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
@IBDesignable open class URLImageView: UIImageView, URLCachableView {
    
    // MARK: - Variables
    
    public private(set) weak var delegate: URLCachableViewDelegate?
    
    public private(set) var sourceURL: URL?
    
    public private(set) var cacheLocation: ResourceCacheLocation = .fileSystem
    
    private var downloadTaskRequest: DownloadTaskRequest!
    
    private var downloadTaskHandler: DownloadTaskHandler<UIImage>?
    
    // Wait for layoutSubviews to set this property
    private var expectedImageSize: CGSize?
    
    private var willWaitForLayoutToGetImageSize: Bool = false
    
    /// A default image used until download completes
    public var defaultImage: UIImage?
    
    
    
    
    
    
    // MARK: - Initializers
    
    public convenience init(delegate: URLCachableViewDelegate?,
                            sourceURLString: String,
                            cacheLocation: ResourceCacheLocation = .fileSystem) {
        self.init(delegate: delegate, cacheLocation: cacheLocation)
        loadImageFrom(urlString: sourceURLString)
    }
    
    public convenience init(delegate: URLCachableViewDelegate?,
                            cacheLocation: ResourceCacheLocation = .fileSystem) {
        self.init(frame: .zero, cacheLocation: cacheLocation)
        self.delegate = delegate
    }
    
    public required init(frame: CGRect, cacheLocation: ResourceCacheLocation) {
        super.init(frame: frame)
        
        if translatesAutoresizingMaskIntoConstraints == true && frame != .zero {
            self.expectedImageSize = frame.size
        }
        
        self.cacheLocation = cacheLocation
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        expectedImageSize = frame.size
        
        if
            willWaitForLayoutToGetImageSize == true,
            image == nil,
            let imageSize = expectedImageSize {
            
            setImage(imageSize: imageSize, completion: imageCompletionHandler)
        }
    }
    
    
    
    
    
    // MARK: - Functions
    
    /// Downloads an image from an external URL string
    public func loadImageFrom(urlString: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.acquireImage(from: urlString, progressHandler: nil, completion: nil, errorHandler: nil)
        }
    }
    
    private var imageCompletionHandler: (() -> ())?
    
    public func loadImageFrom(urlString: String,
                              progressHandler: DownloadTaskProgressHandler?,
                              completion: OptionalCompletionHandler,
                              errorHandler: DownloadTaskErrorHandler?) {
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.acquireImage(from: urlString,
                               progressHandler: progressHandler,
                               completion: completion,
                               errorHandler: errorHandler)
        }
    }
    
    private func acquireImage(from urlString: String,
                              progressHandler: DownloadTaskProgressHandler?,
                              completion: OptionalCompletionHandler,
                              errorHandler: DownloadTaskErrorHandler?) {
        
        DispatchQueue.main.async { [weak self] in
            self?.image = nil
        }
        
        guard let sourceURL = URL(string: urlString) else {
            return
        }
        self.sourceURL = sourceURL
        
        downloadTaskRequest = DownloadTaskRequest(sourceURL: sourceURL, delegate: self)
        
        let resourceExistenceState = Celestial.shared.determineResourceExistenceState(forSourceURL: sourceURL,
                                                                                      ifCacheLocationIsKnown: cacheLocation,
                                                                                      ifResourceTypeIsKnown: .image)
        
        switch resourceExistenceState {
        case .uncached:
            guard let temporaryUncachedFileURL = Celestial.shared.getTemporarilyCachedFileURL(for: sourceURL) else {
                return
            }
            
            prepareAndPossiblyCacheImage(from: temporaryUncachedFileURL)
            
        case .cached:
            
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - getting image from cache")
            if let expectedImageSize = expectedImageSize {
                
                setImage(imageSize: expectedImageSize, completion: completion)
                
            } else {
                
                willWaitForLayoutToGetImageSize = true
                if completion != nil {
                    imageCompletionHandler = completion
                }
            }
            
        case .currentlyDownloading:
            // Use thumbnail?
            fallbackOnDefaultImageIfExists()
            Celestial.shared.mergeExistingDownloadTask(with: downloadTaskRequest)
            
        case .downloadPaused:
            // Use thumbnail?
            Celestial.shared.resumeDownload(downloadTaskRequest: downloadTaskRequest)
            
        case .none:
            
            if progressHandler != nil && completion != nil && progressHandler != nil {
                downloadTaskHandler = DownloadTaskHandler<UIImage>()
                downloadTaskHandler?.completionHandler = { [weak self] (downloadedImage) in
                    self?.useImageOnMainThread(downloadedImage, completion: completion)
                }
                downloadTaskHandler?.progressHandler = { (downloadProgress) in
                    progressHandler?(downloadProgress)
                }
                downloadTaskHandler?.errorHandler = { (error) in
                    errorHandler?(error)
                }
            }
            
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - No resource exists or is currently downloading for url: \(sourceURL). Will start new download")
            
            Celestial.shared.startDownload(downloadTaskRequest: downloadTaskRequest)
        }
    }
    
    private func setImage(imageSize: CGSize, completion: OptionalCompletionHandler) {
        guard let sourceURL = sourceURL else {
            completion?()
            return
        }
        
        switch cacheLocation {
        case .inMemory:
            if let cachedImage = Celestial.shared.imageFromMemoryCache(sourceURLString: sourceURL.absoluteString) {
                useImageOnMainThread(cachedImage, completion: completion)
            } else {
                completion?()
            }
        case .fileSystem:
            guard let cachedImageURL = Celestial.shared.imageURLFromFileCache(sourceURL: sourceURL, pointSize: imageSize) else {
                completion?()
                return
            }
            asyncSetImage(from: cachedImageURL, completion: completion)
            
        default: break
        }
    }
    
    private func asyncSetImage(from cachedImageURL: URL, completion: OptionalCompletionHandler) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            
            guard let cachedImageDataFromURL = try? Data(contentsOf: cachedImageURL) else {
                completion?()
                return
            }
            
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - image data size: \(cachedImageDataFromURL.sizeInMB)")
            
            guard let cachedImage = UIImage(data: cachedImageDataFromURL) else {
                completion?()
                return
            }
            
            let pixelSize = cachedImage.pixelSize
            let scale = cachedImage.scale
            let pointSize = cachedImage.size
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - image pixel size: \(pixelSize). scale: \(scale). point size: \(pointSize)")
            
            self?.useImageOnMainThread(cachedImage, completion: completion)
        }
    }
    
    private func fallbackOnDefaultImageIfExists() {
        DispatchQueue.main.async { [weak self] in
            if let defaultImage = self?.defaultImage {
                self?.image = defaultImage
            }
        }
    }
    
    private func useImageOnMainThread(_ image: UIImage, completion: OptionalCompletionHandler = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.image = image
            completion?()
        }
    }
}

// MARK: - CachableDownloadModelDelegate

extension URLImageView: CachableDownloadModelDelegate {
    
    func cachable(_ downloadTaskRequest: DownloadTaskRequestProtocol, didFinishDownloadingTo intermediateTemporaryFileURL: URL) {
        
        prepareAndPossiblyCacheImage(from: intermediateTemporaryFileURL)
    }
    
    func cachable(_ downloadTaskRequest: DownloadTaskRequestProtocol, downloadFailedWith error: Error) {
        if downloadTaskHandler != nil {
            // This is only called if `loadImageFrom(urlString:, progressHandler:, completion:, errorHandler:)` was called.
            // In which case, this property will be non-nil
            downloadTaskHandler?.errorHandler?(error)
        } else {
            delegate?.urlCachableView?(self, downloadFailedWith: error)
        }
    }
    
    func cachable(_ downloadTaskRequest: DownloadTaskRequestProtocol, downloadProgress progress: Float, humanReadableProgress: String) {
        if downloadTaskHandler != nil {
            // This is only called if `loadImageFrom(urlString:, progressHandler:, completion:, errorHandler:)` was called.
            // In which case, this property will be non-nil
            downloadTaskHandler?.progressHandler?(progress)
        } else {
            delegate?.urlCachableView?(self, downloadProgress: progress, humanReadableProgress: humanReadableProgress)
        }
    }

    
    
    
    private func prepareAndPossiblyCacheImage(from intermediateTemporaryFileURL: URL) {
        
        let desiredImageSize = expectedImageSize ?? UIScreen.main.bounds.size
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let strongSelf = self else { return }
            
            guard let originalSourceURL = strongSelf.sourceURL else {
                let error = CLSError.invalidSourceURLError("The sourceURL does not exist")
                strongSelf.handleDisplayOf(resizedImage: nil, error: error)
                return
            }
            
            switch strongSelf.cacheLocation {
            case .fileSystem:
                
                Celestial.shared.storeDownloadedImageToFileCache(intermediateTemporaryFileURL,
                                                                 withSourceURL: originalSourceURL,
                                                                 pointSize: desiredImageSize,
                                                                 completion: { (resizedImage) in
                                                
                    strongSelf.handleDisplayOf(resizedImage: resizedImage, error: nil)
                })
                
            case .inMemory, .none:
                
                strongSelf.getResizedImage(from: intermediateTemporaryFileURL, desiredImageSize: desiredImageSize) { (resizedImage, error) in
                    if strongSelf.cacheLocation == .inMemory {
                        if let resizedImage = resizedImage {
                            Celestial.shared.storeImageInMemoryCache(image: resizedImage, sourceURLString: originalSourceURL.absoluteString)
                        }
                    } else if strongSelf.cacheLocation == .none {
                        Celestial.shared.deleteFile(at: intermediateTemporaryFileURL)
                    }
                    strongSelf.handleDisplayOf(resizedImage: resizedImage, error: error)
                }
            }
        }
    }
    
    private func getResizedImage(from localTemporaryFileURL: URL, desiredImageSize: CGSize, completion: @escaping (_ resizedImage: UIImage?, _ error: Error?) -> ()) {
        
        do {
            let data = try Data(contentsOf: localTemporaryFileURL)
            guard let originallySizedDownloadedImage = UIImage(data: data) else {
                let error = CLSError.urlToDataError("Could not crete Data from contents of URL: \(localTemporaryFileURL)")
                completion(nil, error)
                return
            }
           
            // Often, the downloaded image is high resolution, and thus very large
                 // in both memory and pixel size.
                 // Create a thumbnail that is the size of the URLImageView that downloaded
                 // it (self).
            let resizedImage = originallySizedDownloadedImage.resize(size: desiredImageSize) ?? originallySizedDownloadedImage
            
            completion(resizedImage, nil)
        } catch let error {
            
            completion(nil, error)
        }
    }
    
    private func handleDisplayOf(resizedImage: UIImage?, error: Error?) {
        if let error = error {
            delegate?.urlCachableView?(self, downloadFailedWith: error)
            return
        }
        
        guard let resizedAndPossiblyCachedImage = resizedImage else {
            return
        }
        
        if downloadTaskHandler != nil {
            // This is only called if `loadImageFrom(urlString:, progressHandler:, completion:, errorHandler:)` was called.
            // In which case, this property will be non-nil
            downloadTaskHandler?.completionHandler?(resizedAndPossiblyCachedImage)
        } else {
            
            useImageOnMainThread(resizedAndPossiblyCachedImage)
            
            delegate?.urlCachableView?(self, didFinishDownloading: resizedAndPossiblyCachedImage)
        }
    }
}
