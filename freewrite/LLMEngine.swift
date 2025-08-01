//
//  LLMEngine.swift
//  freewrite
//
//  Created on 2025-08-01
//

import Foundation
import AppKit

#if canImport(MLX)
import MLX
import MLXLLM
import MLXLMCommon
import Tokenizers
#endif

enum LLMError: Error {
    case modelNotFound
    case failedToLoadModel
    case generationFailed
    case generationCancelled
}

@globalActor
public actor LLMActor {
    public static let shared = LLMActor()
}

/// Singleton wrapper around LLM models running through MLX-Swift.
/// Heavy model loading happens lazily on first use and is isolated to the
/// `LLMActor` so we never block the main thread.
@LLMActor
public final class LLMEngine {
    
    // MARK: – Public access
    public static let shared = LLMEngine()
    
    // MARK: – Private state
#if canImport(MLX)
    private var container: ModelContainer?
    private var isCancelling: Bool = false
#endif
    
    private init() {
        // Listen for memory pressure on macOS
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: "NSApplicationDidReceiveMemoryWarningNotification"),
            object: nil,
            queue: nil) { [weak self] _ in
                Task { await self?.unload() }
        }
    }
    
#if canImport(MLX)
    // Method to allow explicit cancellation
    public func cancelOperations() {
        self.isCancelling = true
        NSLog("LLMEngine: cancelOperations called.")
    }
#endif
    
    // Free the loaded model to release GPU/CPU memory. Safe to call if no
    // generation is in progress.
    func unload() async {
#if canImport(MLX)
        container = nil
        // Shrink MLX buffer cache further to encourage immediate release.
        MLX.GPU.set(cacheLimit: 8 * 1024 * 1024)
#endif
    }
    
    // MARK: – Model loading
    
#if canImport(MLX)
    private func ensureLoaded() async throws {
        if container != nil { return }
        
        // Reduce GPU memory pressure
        MLX.GPU.set(cacheLimit: 4 * 1024 * 1024)
        
        // Get the selected model from LLMModelManager
        guard let selectedModel = await LLMModelManager.shared.selectedModel else {
            throw LLMError.modelNotFound
        }
        
        // Check if the model is downloaded
        guard await LLMModelManager.shared.isModelDownloaded(selectedModel) else {
            throw LLMError.modelNotFound
        }
        
        // Get the model directory
        let modelDir = await LLMModelManager.shared.modelDirectory(for: selectedModel)
        
        // Verify config.json exists
        let configPath = modelDir.appendingPathComponent("config.json")
        guard FileManager.default.fileExists(atPath: configPath.path) else {
            throw LLMError.modelNotFound
        }
        
        let config = ModelConfiguration(directory: modelDir)
        
        let factory = LLMModelFactory.shared
        
        // Register model types that might not be in the current MLXLLM build
        factory.typeRegistry.registerModelType("gemma3_text") { url in
            let configuration = try JSONDecoder().decode(GemmaConfiguration.self, from: Data(contentsOf: url))
            return GemmaModel(configuration)
        }
        
        factory.typeRegistry.registerModelType("qwen3") { url in
            let configuration = try JSONDecoder().decode(Qwen3Configuration.self, from: Data(contentsOf: url))
            return Qwen3Model(configuration)
        }
        
        container = try await factory.loadContainer(configuration: config)
    }
#endif
    
    // MARK: – Prompt helpers
    
#if canImport(MLX)
    private func run(prompt: String, maxTokens: Int = 512) async throws -> String {
        // Initial cancellation check before any heavy work
        if self.isCancelling {
            NSLog("LLMEngine: run() called but isCancelling is true. Aborting before ensureLoaded.")
            throw LLMError.generationCancelled
        }
        
        try await ensureLoaded()
        guard let container else { throw LLMError.failedToLoadModel }
        
        return try await container.perform { (context: ModelContext) async throws -> String in
            
            // Re-check cancellation flags just before starting generation
            let isCancellingAtGenerationStart = await self.isCancelling
            if isCancellingAtGenerationStart {
                NSLog("LLMEngine: Cancellation flag is set before MLX generate. Aborting.")
                throw LLMError.generationCancelled
            }
            
            let messages = [["role": "user", "content": prompt]]
            
            let promptTokens = try context.tokenizer.applyChatTemplate(messages: messages)
            
            let lmInput = LMInput(tokens: MLXArray(promptTokens))
            
            var output = ""
            var parameters = GenerateParameters()
            parameters.temperature = 0.7
            
            // Capture cancellation state before entering the nonisolated closure
            let capturedShouldCancel = await self.isCancelling
            
            // Use callback-style generation; accumulate decoded text.
            _ = try MLXLMCommon.generate(
                input: lmInput,
                parameters: parameters,
                context: context) { tokens in
                    // Use the captured boolean state inside the nonisolated closure
                    if capturedShouldCancel {
                        NSLog("LLMEngine: Captured cancellation flag true during generation. Stopping.")
                        return .stop // Signal MLX to stop generating tokens
                    }
                    
                    guard let last = tokens.last else { return .more }
                    let piece = context.tokenizer.decode(tokens: [last])
                    output += piece
                    return .more
            }
            
            // Check cancellation status *after* generation attempt
            if await self.isCancelling {
                NSLog("LLMEngine: Generation was cancelled. Output may be partial.")
                throw LLMError.generationCancelled
            }
            
            // Remove any <think>...</think> segments entirely.
            let cleaned = output.replacingOccurrences(
                of: #"<think>[\s\S]*?<\/think>"#,
                with: "",
                options: .regularExpression)
            return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
#endif
    
    // MARK: – Public APIs
    
    /// Preload the model into memory for faster first-time processing
    public func preload() async throws {
#if canImport(MLX)
        try await ensureLoaded()
        NSLog("LLMEngine: Model preloaded successfully")
#endif
    }
    
    public func cleanedText(from original: String) async throws -> String {
#if canImport(MLX)
        let prompt = "You are a helpful writing assistant. The user will give you a freewriting text. Rewrite it by correcting grammar, punctuation and typos. Do NOT change the writer's meaning or tone. Return only the cleaned text, no extra commentary.\n\nText:\n\(original)\n\nCleaned text:"
        return try await run(prompt: prompt, maxTokens: 1024)
#else
        return original
#endif
    }
    
    public func summary(for text: String) async throws -> String {
#if canImport(MLX)
        let prompt = "Summarise the following text in 3-4 sentences. Preserve the writer's intent.\n\nText:\n\(text)\n\nSummary:"
        return try await run(prompt: prompt, maxTokens: 256)
#else
        return ""
#endif
    }
    
    public func keyIdeas(for text: String) async throws -> [String] {
#if canImport(MLX)
        let prompt = "Identify the key ideas from the following text. Return them as a bulleted list, one idea per line, at most 10 bullets. Each bullet should briefly elaborate the idea in one sentence.\n\nText:\n\(text)\n\nKey ideas:\n-"
        let raw = try await run(prompt: prompt, maxTokens: 256)
        let bullets = raw
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { line in
                line.trimmingCharacters(in: CharacterSet(charactersIn: "-•").union(.whitespacesAndNewlines))
            }
        return bullets
#else
        return []
#endif
    }
    
    // MARK: – Custom passes
    
    /// Execute an arbitrary user-supplied prompt.  The text will be
    /// appended at the end unless the prompt already contains the
    /// "{{text}}" placeholder – in which case we substitute it.
    ///
    /// - Returns: Raw string produced by the model.
    public func runCustomPrompt(_ template: String, text: String) async throws -> String {
#if canImport(MLX)
        var finalPrompt: String
        if template.contains("{{text}}") {
            finalPrompt = template.replacingOccurrences(of: "{{text}}", with: text)
        } else {
            finalPrompt = "\(template)\n\nText:\n\(text)"
        }
        return try await run(prompt: finalPrompt, maxTokens: 1024)
#else
        return ""
#endif
    }
    
    // MARK: - Batch Processing
    
    /// Process all three enhancements in a single LLM call for better performance
    public func processAllEnhancements(for text: String) async throws -> (cleaned: String, summary: String, keyIdeas: [String]) {
#if canImport(MLX)
        let prompt = """
        You are a helpful writing assistant. Process the following freewriting text and provide three things:

        1. CLEANED TEXT: Correct grammar, punctuation and typos. Do NOT change the writer's meaning or tone.

        2. SUMMARY: Summarize in 3-4 sentences preserving the writer's intent.

        3. KEY IDEAS: List the key ideas as bullets (max 10), briefly elaborating each in one sentence.

        Format your response EXACTLY as follows:
        === CLEANED TEXT ===
        [cleaned text here]

        === SUMMARY ===
        [summary here]

        === KEY IDEAS ===
        - [idea 1]
        - [idea 2]
        - [etc]

        Text:
        \(text)
        """
        
        let response = try await run(prompt: prompt, maxTokens: 2048)
        
        // Parse the response
        let sections = response.components(separatedBy: "===")
        
        var cleaned = text // fallback
        var summary = ""
        var keyIdeas: [String] = []
        
        for (index, section) in sections.enumerated() {
            let content = section.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if content.lowercased().contains("cleaned text") && index + 1 < sections.count {
                cleaned = sections[index + 1]
                    .replacingOccurrences(of: "SUMMARY", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else if content.lowercased().contains("summary") && index + 1 < sections.count {
                summary = sections[index + 1]
                    .replacingOccurrences(of: "KEY IDEAS", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else if content.lowercased().contains("key ideas") && index + 1 < sections.count {
                let ideasText = sections[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                keyIdeas = ideasText
                    .components(separatedBy: "\n")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .map { line in
                        line.trimmingCharacters(in: CharacterSet(charactersIn: "-•").union(.whitespacesAndNewlines))
                    }
            }
        }
        
        return (cleaned: cleaned, summary: summary, keyIdeas: keyIdeas)
#else
        return (cleaned: text, summary: "", keyIdeas: [])
#endif
    }
}