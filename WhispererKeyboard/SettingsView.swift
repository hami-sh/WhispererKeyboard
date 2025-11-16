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
    @State private var customVocabulary: [String] = []
    @State private var newWord: String = ""
    @State private var showingVocabularySaved = false
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
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Custom Vocabulary")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Add words you commonly use that might get misrecognized during transcription. These will help improve accuracy.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("Enter a word or phrase", text: $newWord)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        Button(action: addWord) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(newWord.isEmpty ? .gray : .blue)
                        }
                        .disabled(newWord.isEmpty)
                    }
                    
                    if showingVocabularySaved {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Vocabulary saved")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                    
                    if !customVocabulary.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Saved Words (\(customVocabulary.count))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 6) {
                                    ForEach(customVocabulary.indices, id: \.self) { index in
                                        HStack {
                                            Text(customVocabulary[index])
                                                .font(.subheadline)
                                            Spacer()
                                            Button(action: {
                                                removeWord(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .font(.subheadline)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to get started")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Get your API key from OpenAI", systemImage: "1.circle.fill")
                        Label("Paste it above and save", systemImage: "2.circle.fill")
                        Label("Add custom vocabulary words (optional)", systemImage: "3.circle.fill")
                        Label("Start recording with the keyboard", systemImage: "4.circle.fill")
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
            customVocabulary = Transcription.getCustomVocabulary()
        }
    }
    
    private func saveAPIKey() {
        KeychainHelper.shared.save(apiKey, forKey: "openai_api_key")
        showingSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingSaved = false
        }
    }
    
    private func addWord() {
        let trimmedWord = newWord.trimmingCharacters(in: .whitespaces)
        guard !trimmedWord.isEmpty, !customVocabulary.contains(trimmedWord) else {
            return
        }
        customVocabulary.append(trimmedWord)
        newWord = ""
        saveVocabulary()
    }
    
    private func removeWord(at index: Int) {
        guard index < customVocabulary.count else { return }
        customVocabulary.remove(at: index)
        saveVocabulary()
    }
    
    private func saveVocabulary() {
        Transcription.saveCustomVocabulary(customVocabulary)
        showingVocabularySaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingVocabularySaved = false
        }
    }
}
