//
//  SettingsView.swift
//  freewrite
//
//  Created on 2025-08-01
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var modelManager = LLMModelManager.shared
    @ObservedObject private var passStore = PassStore.shared
    @State private var showAddPassSheet = false
    @State private var showDeleteConfirmation = false
    @State private var passToDelete: LLMPass?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // LLM Model Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Language Model")
                            .font(.system(size: 16, weight: .semibold))
                        
                        if modelManager.downloadedModels.isEmpty {
                            Text("No models downloaded")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(Array(modelManager.downloadedModels), id: \.self) { model in
                                ModelSelectionRow(
                                    model: model,
                                    isSelected: modelManager.selectedModel == model
                                ) {
                                    modelManager.selectedModel = model
                                }
                            }
                        }
                        
                        Button(action: {
                            dismiss()
                            // Show download sheet after a small delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if let contentView = NSApplication.shared.windows.first?.contentView {
                                    // Find the ContentView and trigger the download sheet
                                    NotificationCenter.default.post(name: NSNotification.Name("ShowLLMDownloadSheet"), object: nil)
                                }
                            }
                        }) {
                            Label("Download More Models", systemImage: "arrow.down.circle")
                                .font(.system(size: 13))
                        }
                        .padding(.top, 8)
                    }
                    
                    Divider()
                    
                    // Custom Passes
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Custom Passes")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                            Button(action: { showAddPassSheet = true }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14))
                            }
                        }
                        
                        if passStore.customPasses.isEmpty {
                            Text("No custom passes added")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(passStore.customPasses) { pass in
                                CustomPassRow(pass: pass) {
                                    passToDelete = pass
                                    showDeleteConfirmation = true
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 500, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showAddPassSheet) {
            AddCustomPassSheet()
        }
        .alert("Delete Pass", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let pass = passToDelete,
                   let index = passStore.passes.firstIndex(where: { $0.id == pass.id }) {
                    passStore.delete(at: IndexSet(integer: index))
                }
            }
        } message: {
            Text("Are you sure you want to delete this custom pass?")
        }
    }
}

struct ModelSelectionRow: View {
    let model: LLMModel
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovering = false
    @State private var showDeleteConfirmation = false
    @ObservedObject private var modelManager = LLMModelManager.shared
    
    var body: some View {
        HStack {
            Button(action: action) {
                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.displayName)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                        Text(model.description)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isHovering && !isSelected {
                Button(action: { 
                    showDeleteConfirmation = true 
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Delete this model")
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.gray.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .alert("Delete Model", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                do {
                    try modelManager.deleteModel(model)
                } catch {
                    print("Error deleting model: \(error)")
                }
            }
        } message: {
            Text("Are you sure you want to delete \(model.displayName)? This will free up \(model.estimatedSize) of disk space.")
        }
    }
}

struct CustomPassRow: View {
    let pass: LLMPass
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pass.name)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                Text(String(pass.prompt.prefix(60)) + (pass.prompt.count > 60 ? "..." : ""))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
            }
            .opacity(isHovering ? 1 : 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.gray.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
}