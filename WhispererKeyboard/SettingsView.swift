//
//  SettingsView.swift
//  WhispererKeyboard
//
//  Settings page for configuring OpenAI API key
//

import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var showingSaved = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("OpenAI API Key")) {
                    SecureField("Enter your API key", text: $apiKey)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button("Save API Key") {
                        KeychainHelper.shared.save(apiKey, forKey: "openai_api_key")
                        showingSaved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showingSaved = false
                        }
                    }
                    .disabled(apiKey.isEmpty)
                    
                    if showingSaved {
                        Text("✓ API Key saved securely")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                Section(header: Text("Instructions")) {
                    Text("1. Get your API key from OpenAI")
                    Text("2. Paste it in the field above")
                    Text("3. Click Save")
                    Text("4. Use the keyboard to record and transcribe")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let savedKey = KeychainHelper.shared.get("openai_api_key") {
                apiKey = savedKey
            }
        }
    }
}
