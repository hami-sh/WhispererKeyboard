//
//  SettingsView.swift
//  WhispererKeyboard
//
//  Settings page for configuring OpenAI API key
//
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
            Form {
                // API Key Section
                Section {
                    SecureField("Enter your API key", text: $apiKey)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button("Save API Key") {
                        saveAPIKey()
                    }
                    .disabled(apiKey.isEmpty)
                    
                    if showingSaved {
                        Label("API Key saved securely", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                } header: {
                    Text("OpenAI API Key")
                } footer: {
                    Text("Get your API key from OpenAI and paste it above.")
                }
                
                // Custom Vocabulary Section
                Section {
                    HStack {
                        TextField("Enter a word or phrase", text: $newWord)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        Button(action: addWord) {
                            Image(systemName: showingVocabularySaved ? "checkmark.circle.fill" : "plus.circle.fill")
                                .foregroundStyle(showingVocabularySaved ? .green : (newWord.isEmpty ? .gray : .blue))
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .disabled(newWord.isEmpty)
                    }
                } header: {
                    Text("Custom Vocabulary")
                } footer: {
                    Text("Add words you commonly use that might get misrecognized during transcription. These will help improve accuracy.")
                }
                
                // Vocabulary List
                if !customVocabulary.isEmpty {
                    Section {
                        ForEach(customVocabulary.indices, id: \.self) { index in
                            HStack {
                                Text(customVocabulary[index])
                                Spacer()
                                Button(action: {
                                    removeWord(at: index)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            customVocabulary.remove(atOffsets: indexSet)
                            saveVocabulary()
                        }
                    } header: {
                        Text("Saved Words (\(customVocabulary.count))")
                    }
                }
                
                // Getting Started Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Get your API key from OpenAI")
                        Text("2. Paste it above and save")
                        Text("3. Add custom vocabulary words (optional)")
                        Text("4. Start recording with the keyboard")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                } header: {
                    Text("How to get started")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.blue)
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
        withAnimation {
            showingVocabularySaved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingVocabularySaved = false
            }
        }
    }
}
