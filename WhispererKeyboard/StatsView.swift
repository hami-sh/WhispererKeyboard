//
//  StatsView.swift
//  WhispererKeyboard
//
//  Created for displaying app usage statistics
//

import SwiftUI

struct StatsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var transcriptionCount: Int = 0
    @State private var wordCount: Int = 0
    @State private var showResetConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Transcriptions")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(.secondary)
                            
                            Text("\(transcriptionCount)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 8)
                } footer: {
                    Text("Number of times you've used the app")
                }
                
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Words Spoken")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(.secondary)
                            
                            Text("\(wordCount)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "text.word.spacing")
                            .font(.system(size: 32))
                            .foregroundStyle(.green)
                    }
                    .padding(.vertical, 8)
                } footer: {
                    Text("Total number of words spoken and transcribed")
                }
                Section {
                    Button(role: .destructive, action: {
                        showResetConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Reset Statistics")
                            Spacer()
                        }
                    }
                } footer: {
                    Text("This will permanently delete all statistics. This action cannot be undone.")
                }
            }
            .navigationTitle("Statistics")
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
            .alert("Reset Statistics", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetStats()
                }
            } message: {
                Text("Are you sure you want to reset all statistics? This action cannot be undone.")
            }
        }
        .onAppear {
            loadStats()
        }
    }
    
    private func loadStats() {
        transcriptionCount = StatsManager.shared.getTranscriptionCount()
        wordCount = StatsManager.shared.getWordCount()
    }
    
    private func resetStats() {
        StatsManager.shared.resetStats()
        loadStats()
    }
}

