//
//  DebugLogger.swift
//  Pods
//
//  Created by Chrishon Wyllie on 6/24/20.
//

import Foundation

internal class DebugLogger {
    
    public static let shared = DebugLogger()
    private var debugMessages: [String] = []
    private var withNsLog = true
    
    private let serialQueue = DispatchQueue(label: "com.chrishonwyllie.Celestial.DebugLogger")

    
    
    private init(withNsLog: Bool = true) {
        self.withNsLog = withNsLog
        clear()
    }
    
    public func addDebugMessage(_ message: String) {
        guard Celestial.shared.debugModeIsActive == true else {
            return
        }
        if self.withNsLog {
            #if DEBUG
            NSLog(message)
            #endif
        }
        serialQueue.sync {
            self.debugMessages.append(message)
        }
        
    }
    
    public func getAllMessages() -> [String] {
        return debugMessages
    }
    
    public func clear() {
        debugMessages.removeAll()
    }
}
