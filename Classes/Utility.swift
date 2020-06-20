//
//  Utility.swift
//  Celestial
//
//  Created by Chrishon Wyllie on 6/20/20.
//

import Foundation

internal typealias DownloadProgress = Float
internal typealias DownloadPercentage = String

internal class Utility {
    
    public static let shared = Utility()
    
    
    
    
    
    
    private init() {
        
    }
    
    func getDownloadProgress(totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) -> (DownloadProgress, DownloadPercentage) {
        let downloadProgress: DownloadProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        let totalMediaObjectSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: .file)
        let humanReadableDownloadProgress: DownloadPercentage = String(format: "%.1f%% of %@", downloadProgress * 100, totalMediaObjectSize)
        
        return (downloadProgress, humanReadableDownloadProgress)
    }
}
