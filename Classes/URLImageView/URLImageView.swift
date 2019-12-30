//
//  URLImageView.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import UIKit

public class URLImageView: UIImageView {
    
    // MARK: - Variables
    
    private weak var delegate: URLImageViewDelegate?
    
    public private(set) var cachePolicy: MultimediaCachePolicy = .allow
    
    public private(set) var urlString: String?
    
    private var defaultImage: UIImage?
    
    
    
    
    
    
    
    // MARK: - Initializers
    
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    
    
    
    
    // MARK: - Functions
    
    public func loadImageFrom(urlString: String) {
        
        // Store a reference to the urlString, so that we can save in Cache when download completes
        self.urlString = urlString
        
        //check cache for image first
        if let cachedImage = Celestial.shared.image(for: urlString) {
            self.image = cachedImage
            return
        }
        
        // Otherwise, fire off a new download
        
        let configuration = URLSessionConfiguration.default
        // Setting the delegate queue to nil causes the session to create a
        // serial operation queue to perform all calls to delegate methods and completion handlers.
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        guard let url = URL(string: urlString) else {
            print("MediaCache- Error getting url form urlString")
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
        
        delegate?.urlImageView(self, downloadProgress: percentage, humanReadableProgress: humanReadablePercentage)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        fallbackOnDefaultImageIfExists()
        guard let error = error else { return }
        delegate?.urlImageView(self, downloadFailedWith: error)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        // The location is only temporary. You need to read it or copy it to your container before
        // exiting this function. UIImage(contentsOfFile: ) seems to load the image lazily. NSData
        // does it right away.
        do {
            let data = try Data(contentsOf: location)
            if let downloadedImage = UIImage(data: data) {
                
                DispatchQueue.main.async {
                    self.image = downloadedImage
                }
                
                guard let urlString = self.urlString else { return }
                
                if cachePolicy == .allow {
                    Celestial.shared.store(image: downloadedImage, with: urlString)
                }
                
                delegate?.urlImageView(self, downloadCompletedAt: urlString)
                
            }
        } catch let dataError {
            fallbackOnDefaultImageIfExists()
            delegate?.urlImageView(self, downloadFailedWith: dataError)
        }
    }
    
    private func fallbackOnDefaultImageIfExists() {
        if let defaultImage = defaultImage {
            self.image = defaultImage
        }
    }
    
}
