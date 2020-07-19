//
//  VideoPlayerView.swift
//  Celestial
//
//  Created by Chrishon Wyllie on 6/20/20.
//

import AVFoundation

/// UIView subclass for conveniently allowing for playing
/// videos. Autoresizes with auto layout.
open class VideoPlayerView: UIView {

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
    
}
