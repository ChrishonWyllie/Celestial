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
open class URLImageView: UIImageView, URLCachableView {
    
    // MARK: - Variables
    
    public private(set) weak var delegate: URLCachableViewDelegate?
    
    public private(set) var cachePolicy: MultimediaCachePolicy = .allow
    
    public private(set) var sourceURL: URL?
    
    public private(set) var cacheLocation: DownloadCompletionCacheLocation = .fileSystem
    
    private var downloadModel: GenericDownloadModel!
    
    private var downloadTaskHandler: DownloadTaskHandler<UIImage>?
    
    // Wait for layoutSubviews to set this property
    private var expectedImageSize: CGSize?
    
    private var willWaitForLayoutToGetImageSize: Bool = false
    
    /// A default image used until download completes
    public var defaultImage: UIImage?
    
    
    
    
    
    
    // MARK: - Initializers
    
    public convenience init(delegate: URLCachableViewDelegate?,
                            sourceURLString: String,
                            cachePolicy: MultimediaCachePolicy = .allow,
                            cacheLocation: DownloadCompletionCacheLocation = .fileSystem) {
        self.init(delegate: delegate, cachePolicy: cachePolicy, cacheLocation: cacheLocation)
        loadImageFrom(urlString: sourceURLString)
    }
    
    public convenience init(delegate: URLCachableViewDelegate?,
                            cachePolicy: MultimediaCachePolicy = .allow,
                            cacheLocation: DownloadCompletionCacheLocation = .fileSystem) {
        self.init(frame: .zero, delegate: delegate, cachePolicy: cachePolicy, cacheLocation: cacheLocation)
    }
    
    public required init(frame: CGRect, delegate: URLCachableViewDelegate?, cachePolicy: MultimediaCachePolicy, cacheLocation: DownloadCompletionCacheLocation) {
        super.init(frame: frame)
        
        if translatesAutoresizingMaskIntoConstraints == true && frame != .zero {
            self.expectedImageSize = frame.size
        }
        
        self.delegate = delegate
        self.cachePolicy = cachePolicy
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
        acquireImage(from: urlString, progressHandler: nil, completion: nil, errorHandler: nil)
    }
    
    private var imageCompletionHandler: (() -> ())?
    
    public func loadImageFrom(urlString: String,
                              progressHandler: (DownloadTaskProgressHandler?),
                              completion: (() -> ())?,
                              errorHandler: (DownloadTaskErrorHandler?)) {
        
        acquireImage(from: urlString, progressHandler: progressHandler, completion: completion, errorHandler: errorHandler)
    }
    
    private func acquireImage(from urlString: String, progressHandler: DownloadTaskProgressHandler?, completion: (() -> ())?, errorHandler: DownloadTaskErrorHandler?) {
        image = nil
        
        // Store a reference to the urlString, so that we can save in Cache when download completes
        guard let url = URL(string: urlString) else {
            return
        }
        sourceURL = url
        
        if Celestial.shared.imageExists(for: url, cacheLocation: cacheLocation) {
            
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - getting image from cache")
            if let expectedImageSize = expectedImageSize {
                
                setImage(imageSize: expectedImageSize, completion: completion)
                
            } else {
                
                willWaitForLayoutToGetImageSize = true
                if completion != nil {
                    imageCompletionHandler = completion
                }
                
            }
        } else {
            
            if DownloadTaskManager.shared.downloadIsInProgress(for: url) {
                
                fallbackOnDefaultImageIfExists()
                
            } else {
                
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
                
                finallyBeginFreshDownload(for: url)
            }
        }
    }

    private func finallyBeginFreshDownload(for sourceURL: URL) {
        downloadModel = GenericDownloadModel(sourceURL: sourceURL, delegate: self)
        DownloadTaskManager.shared.startDownload(model: downloadModel)
    }
    
    private func setImage(imageSize: CGSize, completion: (() -> ())?) {
        guard let sourceURL = sourceURL else {
            completion?()
            return
        }
        
        switch cacheLocation {
        case .inMemory:
            if let cachedImage = Celestial.shared.image(for: sourceURL.absoluteString) {
                useImageOnMainThread(cachedImage, completion: completion)
                return
            }
        case .fileSystem:
            guard let cachedImageURL = Celestial.shared.imageURL(for: sourceURL, pointSize: imageSize) else {
                completion?()
                return
            }
            
            DispatchQueue.global(qos: .default).async { [weak self] in
                
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
    }
    
    private func fallbackOnDefaultImageIfExists() {
        if let defaultImage = defaultImage {
            image = defaultImage
        }
    }
    
    private func useImageOnMainThread(_ image: UIImage, completion: (() -> ())? = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.image = image
            completion?()
        }
    }
}

// MARK: - CachableDownloadModelDelegate

extension URLImageView: CachableDownloadModelDelegate {
    
    func cachable(_ downloadTaskRequest: DownloadTaskRequestProtocol, didFinishDownloadingTo localTemporaryFileURL: URL) {
        
        prepareAndPossiblyCacheImage(from: localTemporaryFileURL)
    }
    
    func cachable(_ downloadTaskRequest: DownloadTaskRequestProtocol, downloadFailedWith error: Error) {
        // TODO
        // MUST IMPLEMENT
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

    
    
    
    private func prepareAndPossiblyCacheImage(from localTemporaryFileURL: URL) {
        var imageToDisplay: UIImage?
        let desiredImageSize = expectedImageSize ?? UIScreen.main.bounds.size
        
        switch cachePolicy {
        case .allow:
            
            imageToDisplay = getCachedAndResized(localTemporaryFileURL: localTemporaryFileURL, desiredImageSize: desiredImageSize)
        default:
            imageToDisplay = getResizedImage(from: localTemporaryFileURL, desiredImageSize: desiredImageSize)
            FileStorageManager.shared.deleteFileAt(intermediateTemporaryFileLocation: localTemporaryFileURL)
        }
        
        guard let resizedAndPossiblyCachedImage = imageToDisplay else {
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
    
    private func getCachedAndResized(localTemporaryFileURL: URL, desiredImageSize: CGSize) -> UIImage? {
        
        var resizedCachedImage: UIImage?
        
        guard let originalSourceURL = sourceURL else {
            return nil
        }
        
        switch cacheLocation {
            case .inMemory:
               
                if let resizedImage = getResizedImage(from: localTemporaryFileURL, desiredImageSize: desiredImageSize) {
                    Celestial.shared.store(image: resizedImage, with: originalSourceURL.absoluteString)
                    
                    resizedCachedImage = resizedImage
                }
                
            case .fileSystem:
               
                
                resizedCachedImage = Celestial.shared.storeImageURL(localTemporaryFileURL, withSourceURL: originalSourceURL, pointSize: desiredImageSize)
               
               
        }
        
        return resizedCachedImage
    }
    
    private func getResizedImage(from localTemporaryFileURL: URL, desiredImageSize: CGSize) -> UIImage? {
        
        var resizedImage: UIImage?
        
        do {
            let data = try Data(contentsOf: localTemporaryFileURL)
            guard let untouchedDownloadedImage = UIImage(data: data) else {
                return nil
            }
           
            // Often, the downloaded image is high resolution, and thus very large
                 // in both memory and pixel size.
                 // Create a thumbnail that is the size of the URLImageView that downloaded
                 // it (self).
            resizedImage = untouchedDownloadedImage.resize(size: desiredImageSize) ?? untouchedDownloadedImage
            
            return resizedImage
        } catch let error {
            delegate?.urlCachableView?(self, downloadFailedWith: error)
            return nil
        }
    }
}
