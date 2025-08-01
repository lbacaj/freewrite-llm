//
//  LLMModelManager.swift
//  freewrite
//
//  Created on 2025-08-01
//

import Foundation
import SwiftUI
import ZIPFoundation

@MainActor
public class LLMModelManager: ObservableObject {
    public static let shared = LLMModelManager()
    
    @Published public var selectedModel: LLMModel? {
        didSet {
            if let model = selectedModel {
                UserDefaults.standard.set(model.rawValue, forKey: "selectedLLMModel")
            }
        }
    }
    
    @Published public var downloadProgress: [LLMModel: Double] = [:]
    @Published public var isDownloading: [LLMModel: Bool] = [:]
    @Published public var downloadedModels: Set<LLMModel> = []
    
    private var downloadTasks: [LLMModel: URLSessionDownloadTask] = [:]
    
    private init() {
        // Load saved selection
        if let savedModel = UserDefaults.standard.string(forKey: "selectedLLMModel"),
           let model = LLMModel(rawValue: savedModel) {
            self.selectedModel = model
        }
        
        // Check which models are already downloaded
        Task {
            await checkDownloadedModels()
        }
    }
    
    // MARK: - Model Paths
    
    private var modelsDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("LLMModels")
    }
    
    func modelDirectory(for model: LLMModel) -> URL {
        return modelsDirectory.appendingPathComponent(model.rawValue)
    }
    
    func isModelDownloaded(_ model: LLMModel) -> Bool {
        let modelDir = modelDirectory(for: model)
        let configPath = modelDir.appendingPathComponent("config.json")
        
        // Check if the model is properly extracted
        if FileManager.default.fileExists(atPath: configPath.path) {
            return true
        }
        
        // Check if there's a ZIP file (indicating extraction failed)
        let zipPath = modelDir.appendingPathComponent("\(model.rawValue).zip")
        if FileManager.default.fileExists(atPath: zipPath.path) {
            print("⚠️  Model \(model.displayName) exists as ZIP but is not extracted.")
            return false
        }
        
        return false
    }
    
    // MARK: - Download Management
    
    func checkDownloadedModels() async {
        await MainActor.run {
            var downloaded: Set<LLMModel> = []
            for model in LLMModel.allCases {
                if isModelDownloaded(model) {
                    downloaded.insert(model)
                }
            }
            self.downloadedModels = downloaded
            
            // If no model is selected but we have downloaded models, select one
            if selectedModel == nil && !downloaded.isEmpty {
                selectedModel = downloaded.first
            }
        }
    }
    
    @MainActor
    func downloadModel(_ model: LLMModel) async {
        guard !isDownloading[model, default: false] else { return }
        
        // Clean up any failed previous attempts
        cleanupFailedDownload(model)
        
        isDownloading[model] = true
        downloadProgress[model] = 0.0
        
        do {
            // Create models directory if needed
            try FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
            
            // Download the model
            let localURL = try await downloadWithProgress(from: model.downloadURL) { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?.downloadProgress[model] = progress
                }
            }
            
            // Extract the zip file
            let modelDir = modelDirectory(for: model)
            try await extractZip(from: localURL, to: modelDir)
            
            // Only mark as downloaded if the model was successfully extracted
            if isModelDownloaded(model) {
                // Update downloaded models
                downloadedModels.insert(model)
                
                // If this is the first model, select it
                if selectedModel == nil {
                    selectedModel = model
                }
            } else {
                print("Model \(model.displayName) was downloaded but could not be extracted. It will not be available for use.")
            }
            
        } catch {
            print("Failed to download model \(model.displayName): \(error)")
        }
        
        isDownloading[model] = false
        downloadProgress[model] = nil
    }
    
    @MainActor
    func deleteModel(_ model: LLMModel) throws {
        let modelDir = modelDirectory(for: model)
        try FileManager.default.removeItem(at: modelDir)
        downloadedModels.remove(model)
        
        // If this was the selected model, clear selection
        if selectedModel == model {
            selectedModel = nil
        }
    }
    
    @MainActor
    func cleanupFailedDownload(_ model: LLMModel) {
        let modelDir = modelDirectory(for: model)
        // Remove the entire model directory to clean up any partial downloads
        try? FileManager.default.removeItem(at: modelDir)
        downloadedModels.remove(model)
    }
    
    // MARK: - Helper Methods
    
    private func extractZip(from sourceURL: URL, to destinationURL: URL) async throws {
        print("[LLM] Starting ZIP extraction")
        print("[LLM] Source: \(sourceURL.path)")
        print("[LLM] Destination: \(destinationURL.path)")
        
        // Ensure destination directory exists
        try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        
        do {
            print("[LLM] Attempting to unzip...")
            try FileManager.default.unzipItem(at: sourceURL, to: destinationURL)
            print("[LLM] Successfully unzipped!")
            
            // Handle common macOS zip artefacts (e.g. "__MACOSX") before checking for a nested folder
            
            let allContents = try FileManager.default.contentsOfDirectory(at: destinationURL, includingPropertiesForKeys: nil)
            print("[LLM] Extracted \(allContents.count) items")
            
            // Ignore "__MACOSX" and other hidden files when evaluating the directory structure.
            let relevantContents = allContents.filter { item in
                let name = item.lastPathComponent
                // Ignore __MACOSX folder as well as any ".*" files/folders
                if name == "__MACOSX" || name.hasPrefix(".") {
                    return false
                }
                return true
            }
            
            // Detect and flatten a single nested directory containing the actual model files.
            if relevantContents.count == 1,
               let nestedDir = relevantContents.first,
               nestedDir.hasDirectoryPath,
               !FileManager.default.fileExists(atPath: destinationURL.appendingPathComponent("config.json").path) {
                
                print("[LLM] Detected nested directory structure: \(nestedDir.lastPathComponent)")
                
                let nestedContents = try FileManager.default.contentsOfDirectory(at: nestedDir, includingPropertiesForKeys: nil)
                print("[LLM] Moving \(nestedContents.count) items from nested directory")
                
                for item in nestedContents {
                    let targetPath = destinationURL.appendingPathComponent(item.lastPathComponent)
                    // If a file already exists at the target path (shouldn't happen, but to be safe) remove it first.
                    if FileManager.default.fileExists(atPath: targetPath.path) {
                        try FileManager.default.removeItem(at: targetPath)
                    }
                    try FileManager.default.moveItem(at: item, to: targetPath)
                }
                
                // Remove the now-empty nested directory (and any empty __MACOSX folder)
                try FileManager.default.removeItem(at: nestedDir)
                if let macosxDir = allContents.first(where: { $0.lastPathComponent == "__MACOSX" }) {
                    try? FileManager.default.removeItem(at: macosxDir)
                }
            }
            
            // List final contents
            if let finalContents = try? FileManager.default.contentsOfDirectory(at: destinationURL, includingPropertiesForKeys: nil) {
                print("[LLM] Final contents in \(destinationURL.lastPathComponent):")
                for item in finalContents {
                    print("[LLM]   - \(item.lastPathComponent)")
                }
            }
            
            // Clean up the zip file after successful extraction
            try FileManager.default.removeItem(at: sourceURL)
            print("[LLM] Cleaned up source ZIP")
        } catch {
            print("[LLM] Failed to unzip with error: \(error)")
            // If unzipping fails, remove any partially extracted content
            try? FileManager.default.removeItem(at: destinationURL)
            throw error
        }
    }
}

// MARK: - Download with Progress

extension LLMModelManager {
    private func downloadWithProgress(from url: URL, progressHandler: @escaping (Double) -> Void) async throws -> URL {
        let delegate = DownloadDelegate(progressHandler: progressHandler)
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.downloadTask(with: url) { localURL, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let localURL = localURL {
                    // Move to temporary location to prevent deletion
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                    do {
                        try FileManager.default.moveItem(at: localURL, to: tempURL)
                        continuation.resume(returning: tempURL)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                } else {
                    continuation.resume(throwing: NSError(domain: "LLMModelManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Download failed"]))
                }
            }
            task.resume()
        }
    }
}

private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let progressHandler: (Double) -> Void
    
    init(progressHandler: @escaping (Double) -> Void) {
        self.progressHandler = progressHandler
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        Task { @MainActor in
            self.progressHandler(progress)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // This is handled in the completion handler of downloadTask
        // We don't need to do anything here as the file movement is handled in downloadWithProgress
    }
}