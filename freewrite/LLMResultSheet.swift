//
//  LLMResultSheet.swift
//  freewrite
//
//  Created on 2025-08-01
//

import SwiftUI

struct LLMResultSheet: View {
    @Environment(\.dismiss) private var dismiss
    let passes: [LLMPass]
    @Binding var results: [UUID: String]
    @Binding var processingStatus: [UUID: Bool]
    var onRefresh: (() -> Void)?
    
    @State private var selectedPassId: UUID?
    @State private var editedTexts: [UUID: String] = [:]
    @State private var isEditing: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AI Processing Results")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
                
                // Refresh button
                if let onRefresh = onRefresh {
                    Button(action: {
                        onRefresh()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Reprocess with AI")
                    .disabled(processingStatus.values.contains(true))
                }
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(20)
            
            Divider()
            
            // Tab selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(passes) { pass in
                        TabButton(
                            title: pass.name,
                            isSelected: selectedPassId == pass.id,
                            isProcessing: processingStatus[pass.id] ?? false,
                            hasResult: results[pass.id] != nil
                        ) {
                            selectedPassId = pass.id
                            if isEditing && editedTexts[pass.id] == nil && results[pass.id] != nil {
                                editedTexts[pass.id] = results[pass.id]
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            
            Divider()
            
            // Content area
            if let selectedId = selectedPassId {
                VStack(spacing: 0) {
                    // Toolbar
                    HStack {
                        if processingStatus[selectedId] ?? false {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Processing...")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if results[selectedId] != nil && !(processingStatus[selectedId] ?? false) {
                            HStack(spacing: 12) {
                                // Edit/Save button
                                Button(action: {
                                    if isEditing {
                                        if let editedText = editedTexts[selectedId] {
                                            results[selectedId] = editedText
                                        }
                                    } else {
                                        editedTexts[selectedId] = results[selectedId]
                                    }
                                    isEditing.toggle()
                                }) {
                                    Label(isEditing ? "Save" : "Edit", 
                                          systemImage: isEditing ? "checkmark.circle" : "pencil")
                                        .font(.system(size: 14))
                                }
                                
                                // Copy button
                                Button(action: {
                                    if let text = isEditing ? editedTexts[selectedId] : results[selectedId] {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(text, forType: .string)
                                    }
                                }) {
                                    Label("Copy", systemImage: "doc.on.doc")
                                        .font(.system(size: 14))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    
                    Divider()
                    
                    // Result content
                    ScrollView {
                        if processingStatus[selectedId] ?? false {
                            VStack(spacing: 20) {
                                ProgressView()
                                Text("Processing...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(40)
                        } else if let resultText = results[selectedId] {
                            Group {
                                if isEditing {
                                    TextEditor(text: Binding<String>(
                                        get: { editedTexts[selectedId] ?? resultText },
                                        set: { editedTexts[selectedId] = $0 }
                                    ))
                                    .font(.system(size: 14))
                                    .padding(20)
                                } else {
                                    Text(resultText)
                                        .font(.system(size: 14))
                                        .padding(20)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .textSelection(.enabled)
                                }
                            }
                        } else {
                            Text("Waiting to process...")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(40)
                        }
                    }
                    .background(Color(NSColor.textBackgroundColor))
                }
            } else {
                // No pass selected
                Text("Processing your text with AI...")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 700, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            // Select first available result or first processing pass
            if selectedPassId == nil {
                for pass in passes {
                    if results[pass.id] != nil || (processingStatus[pass.id] ?? false) {
                        selectedPassId = pass.id
                        break
                    }
                }
                // If nothing is ready yet, select the first pass
                if selectedPassId == nil {
                    selectedPassId = passes.first?.id
                }
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let isProcessing: Bool
    let hasResult: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 16, height: 16)
                } else if !hasResult {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.accentColor : Color(NSColor.tertiarySystemFill))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}