//
//  AddCustomPassSheet.swift
//  freewrite
//
//  Created on 2025-08-01
//

import SwiftUI

struct AddCustomPassSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var passStore = PassStore.shared
    
    @State private var passName: String = ""
    @State private var passPrompt: String = ""
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Custom Pass")
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
            
            // Form
            VStack(alignment: .leading, spacing: 20) {
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pass Name")
                        .font(.system(size: 13, weight: .medium))
                    TextField("e.g., Extract Action Items", text: $passName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isNameFocused)
                }
                
                // Prompt field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prompt")
                        .font(.system(size: 13, weight: .medium))
                    Text("Use {{text}} as a placeholder for the content")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $passPrompt)
                        .font(.system(size: 13))
                        .frame(minHeight: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                
                Spacer()
            }
            .padding(20)
            
            Divider()
            
            // Footer buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Add Pass") {
                    passStore.add(name: passName, prompt: passPrompt)
                    dismiss()
                }
                .keyboardShortcut(.return)
                .disabled(passName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                         passPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(20)
        }
        .frame(width: 500, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            isNameFocused = true
        }
    }
}