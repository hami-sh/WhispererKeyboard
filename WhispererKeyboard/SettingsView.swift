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
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("OpenAI API Key")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    SecureField("Enter your API key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if showingSaved {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("API Key saved securely")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.horizontal)
                
                Button(action: saveAPIKey) {
                    Text("Save API Key")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(apiKey.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(apiKey.isEmpty)
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to get started")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Get your API key from OpenAI", systemImage: "1.circle.fill")
                        Label("Paste it above and save", systemImage: "2.circle.fill")
                        Label("Start recording with the keyboard", systemImage: "3.circle.fill")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
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
    
    private func saveAPIKey() {
        KeychainHelper.shared.save(apiKey, forKey: "openai_api_key")
        showingSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingSaved = false
        }
    }
}
