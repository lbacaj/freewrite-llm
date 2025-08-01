//
//  LLMDownloadSheet.swift
//  freewrite
//
//  Created on 2025-08-01
//

import SwiftUI

struct LLMDownloadSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var modelManager = LLMModelManager.shared
    @State private var selectedModel: LLMModel?
    @Binding var onModelSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Download Language Model")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(20)
            
            Divider()
            
            // Model List
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(LLMModel.allCases, id: \.self) { model in
                        ModelRow(
                            model: model,
                            isSelected: selectedModel == model || modelManager.selectedModel == model,
                            isDownloaded: modelManager.downloadedModels.contains(model),
                            isDownloading: modelManager.isDownloading[model] ?? false,
                            downloadProgress: modelManager.downloadProgress[model]
                        ) {
                            if modelManager.downloadedModels.contains(model) {
                                selectedModel = model
                                modelManager.selectedModel = model
                                onModelSelected = true
                                dismiss()
                            } else {
                                Task {
                                    await modelManager.downloadModel(model)
                                    if modelManager.downloadedModels.contains(model) {
                                        selectedModel = model
                                        modelManager.selectedModel = model
                                        onModelSelected = true
                                        dismiss()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            
            Divider()
            
            // Footer
            HStack {
                Text("Models are downloaded to ~/Documents/LLMModels")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(20)
        }
        .frame(width: 600, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct ModelRow: View {
    let model: LLMModel
    let isSelected: Bool
    let isDownloaded: Bool
    let isDownloading: Bool
    let downloadProgress: Double?
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: model.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)
                    .frame(width: 32)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(model.description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Status
                VStack(alignment: .trailing, spacing: 4) {
                    if isDownloading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 20, height: 20)
                        Text("Downloading...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else if isDownloaded {
                        if isSelected {
                            Label("Selected", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.accentColor)
                        } else {
                            Text("Downloaded")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }
                    } else {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Download")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.accentColor)
                            Text(model.estimatedSize)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovering ? Color.gray.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
        }
    }
}