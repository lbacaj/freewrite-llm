//
//  LLMModel.swift
//  freewrite
//
//  Created on 2025-08-01
//

import Foundation

/// Available LLM models for download
public enum LLMModel: String, CaseIterable {
    case qwen3_06B = "Qwen3-0.6B-4bit"
    case qwen3_1_7B = "Qwen3-1.7B-4bit"
    case llama3_2_1B = "Llama-3.2-1B-Instruct-4bit"
    
    var displayName: String {
        switch self {
        case .qwen3_06B:
            return "Qwen 3 (0.6B)"
        case .qwen3_1_7B:
            return "Qwen 3 (1.7B)"
        case .llama3_2_1B:
            return "Llama 3.2 (1B)"
        }
    }
    
    var description: String {
        switch self {
        case .qwen3_06B:
            return "Smaller, faster model. Good for basic summaries."
        case .qwen3_1_7B:
            return "Mid-size model. Higher quality output, slower and uses more memory."
        case .llama3_2_1B:
            return "Apple-optimised 1B Llama 3.2. Balanced quality/performance."
        }
    }
    
    var downloadURL: URL {
        switch self {
        case .qwen3_06B:
            return URL(string: "https://mostack.blob.core.windows.net/models/Qwen3-0.6B-4bit.zip")!
        case .qwen3_1_7B:
            return URL(string: "https://mostack.blob.core.windows.net/models/Qwen3-1.7B-4bit.zip")!
        case .llama3_2_1B:
            return URL(string: "https://mostack.blob.core.windows.net/models/Llama-3.2-1B-Instruct-4bit.zip")!
        }
    }
    
    var iconName: String {
        switch self {
        case .qwen3_06B:
            return "cpu"  // Using system icon for macOS
        case .qwen3_1_7B:
            return "cpu"
        case .llama3_2_1B:
            return "cpu"
        }
    }
    
    var estimatedSize: String {
        switch self {
        case .qwen3_06B:
            return "~200 MB"
        case .qwen3_1_7B:
            return "~900 MB"
        case .llama3_2_1B:
            return "~630 MB"
        }
    }
}