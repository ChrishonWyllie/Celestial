//
//  CachedResourceIdentifierContext.swift
//  Celestial
//
//  Created by Chrishon Wyllie on 7/15/20.
//

import Foundation

internal class CachedResourceIdentifierContext {
    
    private var cachedResourceIdentifiers = Set<CachedResourceIdentifier>()
       
    private let concurrentQueue = DispatchQueue(label: "com.chrishonwyllie.Celestial.CachedResourceIdentifiers.concurrentQueue", attributes: .concurrent)
       
    private let resourceIdentifiersKey = "com.chrishonwyllie.Celestial.CachedResourceIdentifiers.UserDefaults.key"
    
    
    
    
    
    
    init() {
        loadCachedResourceIdentifiers()
    }
    
    
    
    
    
    internal func storeReferenceTo(cachedResource: CachedResourceIdentifier) {
        
        concurrentQueue.async(flags: .barrier) { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.cachedResourceIdentifiers.contains(cachedResource) == false else {
                return
            }
            
            strongSelf.cachedResourceIdentifiers.insert(cachedResource)
            
            do {
                let encodedData = try PropertyListEncoder().encode(strongSelf.cachedResourceIdentifiers)
                UserDefaults.standard.set(encodedData, forKey: strongSelf.resourceIdentifiersKey)
            } catch let error {
                DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error encoding resource identifiers array to data. Error: \(error)")
            }
        }
    }
    
    private func loadCachedResourceIdentifiers() {
        
        guard
            let cachedResourcesData = UserDefaults.standard.value(forKey: resourceIdentifiersKey) as? Data,
            let locallyStoredCachedResourceReferences = try? PropertyListDecoder().decode(Set<CachedResourceIdentifier>.self, from: cachedResourcesData) else {
                
            cachedResourceIdentifiers = []
            return
        }
        cachedResourceIdentifiers = locallyStoredCachedResourceReferences
    }
    
    internal func removeResourceIdentifier(for sourceURLString: String) {
        
        guard let sourceURL = URL(string: sourceURLString) else {
            fatalError("\(sourceURLString) is not a valid URL")
        }
        concurrentQueue.async(flags: .barrier) { [weak self] in
            guard let strongSelf = self else { return }
            guard
                strongSelf.cachedResourceIdentifiers.count > 0 else {
                return
            }
            
            guard let resourceIdentifierToRemove = strongSelf.cachedResourceIdentifiers.filter({ (identifier) -> Bool in
                return identifier.sourceURL == sourceURL
            }).first else {
                return
            }
            
            strongSelf.cachedResourceIdentifiers.remove(resourceIdentifierToRemove)
            strongSelf.saveResourceIdentifiersInUserDefaults()
        }
    }
    
    internal func clearAllResourceIdentifiers() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.cachedResourceIdentifiers.count > 0 else {
                return
            }
            strongSelf.cachedResourceIdentifiers.removeAll(keepingCapacity: false)
            strongSelf.saveResourceIdentifiersInUserDefaults()
        }
    }
    
    internal func clearResourceIdentifiers(withResourceType resourceType: ResourceFileType) {
        concurrentQueue.async(flags: .barrier) { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.cachedResourceIdentifiers.count > 0 else {
                return
            }
            
            let resourceIdentifiersToRemove = strongSelf.cachedResourceIdentifiers.filter({ (identifier) -> Bool in
                return identifier.resourceType == resourceType
            })
            
            for identifier in resourceIdentifiersToRemove {
                strongSelf.cachedResourceIdentifiers.remove(identifier)
            }
            
            strongSelf.saveResourceIdentifiersInUserDefaults()
        }
    }
    
    private func saveResourceIdentifiersInUserDefaults() {
        do {
            let encodedData = try PropertyListEncoder().encode(cachedResourceIdentifiers)
            UserDefaults.standard.set(encodedData, forKey: resourceIdentifiersKey)
        } catch let error {
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Error encoding resource identifiers array to data. Error: \(error)")
        }
    }
    
    internal func resourceIdentifier(for sourceURL: URL) -> CachedResourceIdentifier? {
        concurrentQueue.sync { [weak self] in
            guard let cachedResourceReferencesMatchingURL = self?.cachedResourceIdentifiers.filter({ $0.sourceURL == sourceURL }) else {
                return nil
            }
            
            DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Filtering for CachedResourceIdentifier matching url: \(sourceURL). Resource identifiers:")
            
            for identifier in self?.cachedResourceIdentifiers ?? [] {
                DebugLogger.shared.addDebugMessage("\(identifier)")
            }
            
            if cachedResourceReferencesMatchingURL.count > 1 {
                fatalError("Internal inconsistency. There can only be 0 (non-existent) or 1 identifier for a single URL: \(sourceURL). Found \(cachedResourceReferencesMatchingURL.count) matching results: \(cachedResourceReferencesMatchingURL)")
            }
            
            return cachedResourceReferencesMatchingURL.first
        }
    }
    
    internal func resourceIdentifierExists(for sourceURL: URL) -> Bool {
        
        var resourceExists: Bool = false
        
        if let resourceIdentifier = resourceIdentifier(for: sourceURL) {
            
            resourceExists = true
            
            switch resourceIdentifier.cacheLocation {
            case .none:
                return false
            case .inMemory:
                break
            case .fileSystem:
                if let info = FileStorageManager.shared.getInfoForStoredResource(matchingSourceURL: resourceIdentifier.sourceURL,
                                                                                 fileType: resourceIdentifier.resourceType) {
                
                    if info.fileSize == 0 {
                        // Upon further inspection,
                        // the file does not actually exist.
                        // There is no data at the specified file URL.
                        // An error may have occured, such as moving app to background
                        // during some process that cannot continue unless app
                        // is in foreground
                        // Such as AVAssextExportSession for videos
                        
                        try? FileManager.default.removeItem(at: info.fileURL)
                        
                        resourceExists = false
                    }
                } else {
                    resourceExists = false
                }
            }
        }
        
        return resourceExists
    }
    
}
