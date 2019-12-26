//
//  MiscellaneousDeclarations.swift
//  Pods
//
//  Created by Chrishon Wyllie on 12/25/19.
//

import Foundation

// MARK: - URLImageView

public protocol URLImageViewDelegate: class {
    func urlImageView(_ view: URLImageView, downloadCompletedAt urlString: String)
    func urlImageView(_ view: URLImageView, downloadFailedWith error: Error)
    func urlImageView(_ view: URLImageView, downloadProgress progress: CGFloat, humanReadableProgress: String)
}

public enum URLImageViewCachePolicy {
    case allow
    case notAllowed
}
