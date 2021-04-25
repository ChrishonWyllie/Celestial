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
    
    /// Returns the size required to fit within the given
    /// width that would maintain the proper aspect ratio
    public func requiredSizeFor(width: CGFloat) -> CGSize {
        guard let resolution = resolution, resolution != .zero else {
            return .zero
        }
        
        /*
         Find the missing heightA. widthB and heightB
         widthA (containerSize)         widthB (resolution.width)
         ------                 =       ------
         heightA (unknown)              heightB (resolution.height)
         */
        let calculatedHeight: CGFloat = (width * resolution.height) / resolution.width
        let calculatedContainerSize: CGSize = CGSize(width: width, height: calculatedHeight)
        let containingRect: CGRect = .init(origin: .zero, size: calculatedContainerSize)
        
        let desiredVideoRect = AVMakeRect(aspectRatio: resolution, insideRect: containingRect)
        
        return desiredVideoRect.size
        
    }
    
    open override var intrinsicContentSize: CGSize {
        return self.requiredSizeFor(width: UIScreen.main.bounds.size.width)
    }
}
