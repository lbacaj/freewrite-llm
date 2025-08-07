//
//  LLMPass.swift
//  freewrite
//
//  Created on 2025-08-01
//

import Foundation

/// Represents a single transformation ("pass") the LLM can perform on a note.
/// Built-in passes are compiled into the app and cannot be removed by users.
/// Custom passes are persisted on disk so they survive reinstalls.
struct LLMPass: Identifiable, Codable, Equatable {
    
    enum Kind: String, Codable {
        case builtIn
        case custom
    }
    
    let id: UUID
    var name: String
    var prompt: String
    var kind: Kind
    
    /// Built-in passes are protected from user deletion.
    var isProtected: Bool { kind == .builtIn }
    
    init(id: UUID = .init(), name: String, prompt: String, kind: Kind) {
        self.id = id
        self.name = name
        self.prompt = prompt
        self.kind = kind
    }
}

// MARK: – Predefined core passes

extension LLMPass {
    
    /// Returns the three core passes the app has always supported.
    ///
    /// We use stable UUIDs so the IDs stay consistent across reinstallations
    /// which is useful for persisting results keyed by `id`.
    static let builtIns: [LLMPass] = [
        LLMPass(
            id: UUID(uuidString: "A71924C8-02C4-4517-9E37-701F7A2FE0FD")!,
            name: "Core Ideas",
            prompt: "Identify the key ideas from the following text. Return them as a bulleted list, one idea per line, at most 10 bullets. Each bullet should briefly elaborate the idea in one sentence.",
            kind: .builtIn
        ),
        LLMPass(
            id: UUID(uuidString: "C8F2A934-B906-411B-AF0F-182A64EE3C4F")!,
            name: "Clean Up",
            prompt: "Rewrite the text by correcting grammar, punctuation and typos. Do NOT change the writer's meaning or tone. Keep the original paragraph structure. Return only the cleaned text, no extra commentary.",
            kind: .builtIn
        ),
        LLMPass(
            id: UUID(uuidString: "5FBB58F7-0EFD-4F29-B9BA-3978B995DB6C")!,
            name: "Writing Feedback",
            prompt: "Provide constructive feedback on this writing using the CRIBS framework (Confusing, Repeated, Interesting, Boring, Surprising). Focus on the writing quality and clarity of thought, not grammar or syntax. If this appears to be a journal entry, also provide feedback on the clarity and coherence of the thoughts expressed. Format your response as follows:\n\n## Strengths\n- What works well in this writing\n\n## Areas for Improvement\n- Confusing: Any unclear or ambiguous sections\n- Repeated: Redundant ideas or phrases\n- Boring: Parts that lose engagement\n\n## Notable Elements\n- Interesting: Engaging or compelling parts\n- Surprising: Unexpected insights or turns\n\n## Overall Feedback\nBrief constructive advice for improving the writing",
            kind: .builtIn
        )
    ]
}