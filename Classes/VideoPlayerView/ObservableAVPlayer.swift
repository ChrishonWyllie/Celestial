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
            let status: AVPlayerItem.Status
            
            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue) ?? .unknown
            } else {
                status = .unknown
            }
            
            delegate?.observablePlayer(self, didLoadChangePlayerItem: status)
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
