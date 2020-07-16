//
//  DownloadTaskRequest.swift
//  Pods
//
//  Created by Chrishon Wyllie on 6/23/20.
//

import Foundation

/// Initiates a download
internal protocol DownloadTaskRequestProtocol {
    /// Current progress of a download. To update UI, use `CachableDownloadModelDelegate`
    var progress: Float { get }
    /// Partial Data as a result of pausing a download. May be used to resume if desired
    var resumeData: Data? { get }
    /// `URLSessionDownloadTask` used to download the desired resource
    var task: URLSessionDownloadTask? { get }
    /// The URL of the resource to be downloaded
    var sourceURL: URL { get }
    /// The state of the current download. For updating UI with download state,
    /// it is best to use the `CachableDownloadModelDelegate`
    var downloadState: DownloadTaskState { get }
    /// Used to notify receiver of download state events such as completion, progress and errors
    var delegate: CachableDownloadModelDelegate? { get set }
    
    /**
     Initializes a object representing a download task as well as supporting information

    - Parameters:
       - sourceURL: The URL of the resource to be downloaded
       - delegate: The receiver of events pertaining to the download such as progress, completion or errors
    */
    init(sourceURL: URL, delegate: CachableDownloadModelDelegate?)
}

/// Initiates a download request
internal class DownloadTaskRequest: DownloadTaskRequestProtocol, CustomStringConvertible, Codable {
    private(set) var progress: Float = 0
    private(set) var resumeData: Data?
    private(set) var task: URLSessionDownloadTask?
    
    private(set) var sourceURL: URL
    private(set) var downloadState: DownloadTaskState = .none
    weak var delegate: CachableDownloadModelDelegate?
    
    private enum CodingKeys: String, CodingKey {
        case sourceURL
        case progress
        case resumeData
        case downloadState
    }
    
    
    
    
    required init(sourceURL: URL, delegate: CachableDownloadModelDelegate?) {
        self.sourceURL = sourceURL
        self.delegate = delegate
    }
    
    
    
    func setProgress(_ progress: Float) {
        self.progress = progress
    }
    
    func storeResumableData(_ resumeData: Data) {
        self.resumeData = resumeData
    }
    
    func prepareForDownload(task: URLSessionDownloadTask) {
        self.task = task
    }
    
    func update(downloadState: DownloadTaskState) {
        self.downloadState = downloadState
    }
    
    var description: String {
        let printableString = "Progress: \(progress), resumeData coutn if previously paused: \(String(describing: resumeData?.count)), task: \(String(describing: task)), source URL: \(sourceURL), download state: \(downloadState)"
        return printableString
    }
    
    
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        sourceURL = try container.decode(URL.self, forKey: .sourceURL)
        progress = try container.decode(Float.self, forKey: .progress)
        let downloadStateRawValue = try container.decode(Int.self, forKey: .downloadState)
        downloadState = DownloadTaskState(rawValue: downloadStateRawValue) ?? .none
        resumeData = try container.decode(Data.self, forKey: .resumeData)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(sourceURL, forKey: .sourceURL)
        try container.encode(progress, forKey: .progress)
        try container.encode(downloadState.rawValue, forKey: .downloadState)
        try container.encode(resumeData, forKey: .resumeData)
    }
    
}
