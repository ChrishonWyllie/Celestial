//
//  AssetExportManager.swift
//  Celestial
//
//  Created by Chrishon Wyllie on 4/22/21.
//

import AVFoundation

/**
 This object handles the video export sessions
 
 Videos that are exported with different quality versions (such as `low` or `medium`) will utilize the functions in this class
 */
internal class AssetExportManager: NSObject {
    
    // MARK: - Variables
    
    fileprivate struct VideoExportInstructions {
        let layerInstruction: AVMutableVideoCompositionLayerInstruction
        let videoRenderSize: CGSize
        let videoIsPortrait: Bool
        let videoOrientation: UIImage.Orientation
    }
    
    fileprivate struct ExportSessionInfo {
        let outputURL: URL
        let composition: AVMutableComposition
        let videoComposition: AVMutableVideoComposition
        let duration: CMTime
        let exportQuality: Celestial.VideoExportQuality
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    // MARK: - Functions
    
    internal static func exportVideo(fromIntermediateFileURL intermediateTemporaryFileURL: URL, outputURL: URL, videoExportQuality: Celestial.VideoExportQuality, completion: @escaping MediaAssetCompletionHandler) {
        let assetKeys: [URLVideoPlayerView.LoadableAssetKeys] = [.tracks, .exportable]
        DispatchQueue.global(qos: .utility).async {
            AVURLAsset.prepareUsableAsset(withAssetKeys: assetKeys, inputURL: intermediateTemporaryFileURL) { (exportableAsset, error) in
                
                guard let exportSession = buildExportSession(withLocalOutputURL: outputURL, usingAsset: exportableAsset, exportQuality: videoExportQuality) else {
                    let error = NSError.createError(withString: "Could not initialize an AVAssetExportSession",
                                                    description: "Could not initialize an AVAssetExportSession. Check the buildExportSession(withLocalOutputURL:...) function for possible causes",
                                                    comment: nil,
                                                    domain: "UnableToCreateExportSession",
                                                    code: 1)
                    completion(nil, error)
                    return
                }
                
                exportSession.exportAsynchronously {
                    switch exportSession.status {
                    case .exporting:
                        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - Exporting video for url: \(outputURL). Progress: \(exportSession.progress)")
                        
                    case .completed:
                        completion(outputURL, nil)
                    case .failed:
                        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - failed to export url: \(outputURL). Error: \(String(describing: exportSession.error))")
                        completion(nil, exportSession.error)
                        
                    case .cancelled:
                        DebugLogger.shared.addDebugMessage("\(String(describing: type(of: self))) - export for url: \(outputURL) cancelled")
                        if let error = exportSession.error {
                            completion(nil, error)
                        } else {
                            let error = NSError.createError(withString: "The AVAssetExportSession has cancelled its export session",
                                                            description: "The AVAssetExportSession has cancelled its export session",
                                                            comment: nil,
                                                            domain: "AVAssetExportSessionExportCancelled",
                                                            code: 1)
                            completion(nil, error)
                        }
                        completion(nil, exportSession.error)
                        
                    case .unknown: break
                    case .waiting: break
                    @unknown default:
                        fatalError()
                    }
                }
            }
        }
    }
    
    private static func buildExportSession(withLocalOutputURL outputURL: URL, usingAsset asset: AVURLAsset, exportQuality: Celestial.VideoExportQuality) -> AVAssetExportSession? {
        guard asset.isExportable else {
            return nil
        }
        
        try? FileManager.default.removeItem(at: outputURL)

        let composition = AVMutableComposition()
        guard
            let compositionVideoTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                      preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid)),
            let compositionAudioTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                      preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid)) else {
            return nil
        }

        guard
            let sourceVideoTrack = asset.tracks(withMediaType: AVMediaType.video).first,
            let sourceAudioTrack = asset.tracks(withMediaType: AVMediaType.audio).first
            else {
                return nil
        }
        
        do {
            try compositionVideoTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: asset.duration), of: sourceVideoTrack, at: CMTime.zero)
            try compositionAudioTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: asset.duration), of: sourceAudioTrack, at: CMTime.zero)
        } catch(_) {
            return nil
        }
        
        let videoComposition: AVMutableVideoComposition = buildVideoComposition(composition: composition, compositionVideoTrack: compositionVideoTrack, sourceVideoTrack: sourceVideoTrack)
        
        let exportSessionInfo = ExportSessionInfo(outputURL: outputURL,
                                                  composition: composition,
                                                  videoComposition: videoComposition,
                                                  duration: asset.duration,
                                                  exportQuality: exportQuality)
        guard let exportSession = buildExportSession(withExportSessionInformation: exportSessionInfo) else {
            return nil
        }
        return exportSession
    }
    
    private static func buildVideoComposition(composition: AVMutableComposition, compositionVideoTrack: AVMutableCompositionTrack, sourceVideoTrack: AVAssetTrack) -> AVMutableVideoComposition {
        compositionVideoTrack.preferredTransform = sourceVideoTrack.preferredTransform
        
        let videoExportInstructions: VideoExportInstructions = buildVideoExportInstructions(for: compositionVideoTrack, sourceVideoTrack: sourceVideoTrack)
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoExportInstructions.videoRenderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
        instruction.layerInstructions = [videoExportInstructions.layerInstruction]
        videoComposition.instructions = [instruction]
        
        return videoComposition
    }
    
    
    private static func buildVideoExportInstructions(for track: AVMutableCompositionTrack, sourceVideoTrack: AVAssetTrack) -> VideoExportInstructions {
      
        var videoOrientation = UIImage.Orientation.up
        var isPortrait = false
        
        let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
         
        var transform = sourceVideoTrack.preferredTransform
        
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            // Right
            videoOrientation = .right
            isPortrait = true
            let rotate = CGAffineTransform.identity.translatedBy(x: sourceVideoTrack.naturalSize.height - sourceVideoTrack.preferredTransform.tx, y: -sourceVideoTrack.preferredTransform.ty)
            transform = sourceVideoTrack.preferredTransform.concatenating(rotate)
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            // Left
            videoOrientation = .left
            isPortrait = true
            let rotate = CGAffineTransform.identity.translatedBy(x: -sourceVideoTrack.preferredTransform.tx, y: sourceVideoTrack.naturalSize.width - sourceVideoTrack.preferredTransform.ty)
            transform = sourceVideoTrack.preferredTransform.concatenating(rotate)
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            // Up
            videoOrientation = .up
            transform = sourceVideoTrack.preferredTransform
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            // Down
            videoOrientation = .down
            let rotate = CGAffineTransform.identity.translatedBy(x: sourceVideoTrack.naturalSize.width - sourceVideoTrack.preferredTransform.tx, y: sourceVideoTrack.naturalSize.height - sourceVideoTrack.preferredTransform.ty)
            transform = sourceVideoTrack.preferredTransform.concatenating(rotate)
        }

        videoLayerInstruction.setTransform(transform, at: .zero)
         
        let videoRenderSize: CGSize
        if isPortrait {
            videoRenderSize = CGSize(width: sourceVideoTrack.naturalSize.height, height: sourceVideoTrack.naturalSize.width)
        } else {
            videoRenderSize = sourceVideoTrack.naturalSize
        }
       
        return VideoExportInstructions(layerInstruction: videoLayerInstruction,
                                       videoRenderSize: videoRenderSize,
                                       videoIsPortrait: isPortrait,
                                       videoOrientation: videoOrientation)
    }
    
    private static func buildExportSession(withExportSessionInformation exportSessionInfo: ExportSessionInfo) -> AVAssetExportSession? {
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: exportSessionInfo.composition)
        var preset: String = AVAssetExportPresetPassthrough
        
        switch exportSessionInfo.exportQuality {
        case .default: break
        case .low: if compatiblePresets.contains(AVAssetExportPresetLowQuality) { preset = AVAssetExportPresetLowQuality }
        case .medium: if compatiblePresets.contains(AVAssetExportPresetMediumQuality) { preset = AVAssetExportPresetMediumQuality }
        }
        
        guard
            let exportSession = AVAssetExportSession(asset: exportSessionInfo.composition, presetName: preset),
            exportSession.supportedFileTypes.contains(AVFileType.mp4) else {
            return nil
        }
        
        exportSession.outputURL = exportSessionInfo.outputURL
        exportSession.videoComposition = exportSessionInfo.videoComposition
        exportSession.outputFileType = AVFileType.mp4
        let startTime = CMTimeMake(value: 0, timescale: 1)
        let timeRange = CMTimeRangeMake(start: startTime, duration: exportSessionInfo.duration)
        exportSession.timeRange = timeRange
        exportSession.shouldOptimizeForNetworkUse = true
        
        return exportSession
    }
}
