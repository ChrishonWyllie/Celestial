//
//  ObservableAVPlayer.swift
//  Celestial
//
//  Created by Chrishon Wyllie on 7/10/20.
//

import AVFoundation

internal class ObservableAVPlayer: AVPlayer, ObservablePlayerProtocol {
    
    internal private(set) weak var delegate: ObservableAVPlayerDelegate?
    
    internal private(set) var playerItemContext: Int = 0
    
    private var didAddObserver: Bool = false
    
    internal private(set) var isPlaying: Bool = false
    
    required init(playerItem item: AVPlayerItem, delegate: ObservableAVPlayerDelegate) {
        super.init(playerItem: item)
        observePlayerStatus()
        self.delegate = delegate
        
    }
    
    override init(playerItem item: AVPlayerItem?) {
        super.init(playerItem: item)
    }
    
    override init() {
        super.init()
    }
    
    override func play() {
        super.play()
        isPlaying = true
    }
    
    override func pause() {
        super.pause()
        isPlaying = false
    }
    
    private func observePlayerStatus() {
        didAddObserver = true
        currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &playerItemContext)
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        // Only handle observations for the playerItemContext
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            
            // Get the status change from the change dictionary
            
            guard
                let oldStatusValue = change?[.oldKey] as? NSNumber,
                let newStatusValue = change?[.newKey] as? NSNumber else {
                return
            }
            
            if oldStatusValue != newStatusValue {
                // Status has changed
                guard let status: AVPlayerItem.Status = AVPlayerItem.Status(rawValue: newStatusValue.intValue) else {
                    return
                }
                delegate?.observablePlayer(self, didLoadChangePlayerItem: status)
            }
        }
    }
    
    internal func reset() {
        if didAddObserver {
            currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
            didAddObserver = false
        }
    }
    
    deinit {
        reset()
        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - is being deinitialized")
    }
}
