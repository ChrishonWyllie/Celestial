//
//  DownloadTaskRequest.swift
//  Pods
//
//  Created by Chrishon Wyllie on 6/23/20.
//

import Foundation

internal protocol DownloadTaskRequestProtocol {
    var progress: Float { get }
    var resumeData: Data? { get }
    var task: URLSessionDownloadTask? { get }
    var downloadObject: DownloadModelRepresentable { get }
}

internal class DownloadTaskRequest: DownloadTaskRequestProtocol {
    var progress: Float = 0
    var resumeData: Data?
    var task: URLSessionDownloadTask?
    var downloadObject: DownloadModelRepresentable
    
    init(downloadObject: DownloadModelRepresentable) {
        self.downloadObject = downloadObject
    }
}
