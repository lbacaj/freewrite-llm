//
//  PassStore.swift
//  freewrite
//
//  Created on 2025-08-01
//

import Foundation
import SwiftUI

/// Centralised store that keeps track of all LLM passes (built-in + user defined).
/// Custom passes are persisted to disk in a simple JSON file.
///
/// Built-in passes are exposed through `LLMPass.builtIns` and merged with the
/// saved custom list when the singleton initialises.
@MainActor
final class PassStore: ObservableObject {
    
    // MARK: – Public API
    
    static let shared = PassStore()
    
    /// All passes shown in the UI and executed on notes.  The array always
    /// contains the three core passes followed by any user-created ones.
    @Published private(set) var passes: [LLMPass] = []
    
    /// Convenience access to the subset the user can edit.
    var customPasses: [LLMPass] { passes.filter { $0.kind == .custom } }
    
    // MARK: – Init / persistence
    
    private init() {
        passes = LLMPass.builtIns + loadCustom()
    }
    
    private static var storeURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("custom_passes.json")
    }
    
    private func loadCustom() -> [LLMPass] {
        guard let data = try? Data(contentsOf: Self.storeURL) else { return [] }
        return (try? JSONDecoder().decode([LLMPass].self, from: data)) ?? []
    }
    
    private func persistCustom() {
        let customs = passes.filter { $0.kind == .custom }
        do {
            let data = try JSONEncoder().encode(customs)
            try data.write(to: Self.storeURL, options: .atomic)
        } catch {
            print("⚠️ Failed to save custom passes: \(error)")
        }
    }
    
    // MARK: – CRUD helpers
    
    func add(name: String, prompt: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedPrompt.isEmpty else { return }
        
        let new = LLMPass(name: trimmedName, prompt: trimmedPrompt, kind: .custom)
        passes.append(new)
        persistCustom()
    }
    
    func delete(at offsets: IndexSet) {
        // Prevent removing built-in passes even if indices somehow include them.
        let victims = offsets.map { passes[$0] }
        guard victims.allSatisfy({ !$0.isProtected }) else { return }
        
        passes.remove(atOffsets: offsets)
        persistCustom()
    }
}