//
//  VideoPlayerView.swift
//  Celestial
//
//  Created by Chrishon Wyllie on 6/20/20.
//

import AVFoundation

/// UIView subclass for conveniently allowing for playing
/// videos. Autoresizes with auto layout.
@IBDesignable open class VideoPlayerView: UIView {

    public override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    public var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }

    public var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    /// Returns the resolution of the video in pixel format (e.g. 1080 Width by 1980 Height for a vertical video or 9:16 format)
    /// NOTE: This will be nil or zero until the video is ready to play
    public var resolution: CGSize? {
        return self.player?.currentItem?.resolution
    }
    
    /// Returns the aspect ratio of the video represented as a double
    public var aspectRatio: Double? {
        return self.player?.currentItem?.aspectRatio
    }
    
    /// Returns a CGSize that takes the video resolution into account and the size of its container
    public func sizeFittingWithin(containerSize: CGSize) -> CGSize {
        guard let resolution = resolution, resolution != .zero else {
            return .zero
        }
        let containingRect: CGRect = .init(origin: .zero, size: containerSize)
        let desiredVideoRect = AVMakeRect(aspectRatio: resolution, insideRect: containingRect)
        
        return desiredVideoRect.size
    }
    
}
