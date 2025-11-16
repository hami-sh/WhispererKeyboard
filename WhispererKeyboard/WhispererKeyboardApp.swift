//
//  WhispererKeyboardApp.swift
//  WhispererKeyboard
//
//  Created by Alexander Steshenko on 9/11/23.
//

import SwiftUI
import Foundation
import AVFoundation

/// This is a full screen view that opens up when "Record audio" button is clicked in the keyboard extension
/// When open, the app automatically begins recording. Once finished, the application requests transcriptiong using OpenAI Whisperer API
/// The app then suggests the user to return to the app that had the keyboard open. Unfortunately found no way to return user automatically.
@main
struct WhispererKeyboardApp: App {
    
    // contains logic for capturing audio from the microphone and saving into a temporary file
    private var audio = Audio()
    
    // contains logic for sending data for transcription to OpenAI and storing results into shared app storage
    @StateObject private var transcription = Transcription()
    
    // Necessary to detect when application becomes active. Begin recording immediately
    @Environment(\.scenePhase) var scenePhase
    
    // Track whether we should show settings or recording view
    @State private var showSettings = false
    @State private var openedViaURLScheme = false
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                audio: audio,
                transcription: transcription,
                showSettings: $showSettings,
                openedViaURLScheme: $openedViaURLScheme
            )
            .onOpenURL { url in
                if url.scheme == "WhispererKeyboardApp" {
                    openedViaURLScheme = true
                    transcription.status = .recording
                    audio.start()
                }
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active && !openedViaURLScheme {
                    // Reset state when app comes to foreground normally
                    transcription.status = .recording
                    transcription.transcribedText = ""
                }
            }
        }
    }
}

struct ContentView: View {
    let audio: Audio
    @ObservedObject var transcription: Transcription
    @Binding var showSettings: Bool
    @Binding var openedViaURLScheme: Bool
    @State private var refreshWelcome = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if openedViaURLScheme {
                    RecordingView(
                        audio: audio,
                        transcription: transcription,
                        openedViaURLScheme: $openedViaURLScheme
                    )
                    .transition(.opacity)
                } else {
                    WelcomeView(refresh: refreshWelcome)
                        .transition(.opacity)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .medium))
                    }
                }
            }
            .sheet(isPresented: $showSettings, onDismiss: {
                refreshWelcome.toggle()
            }) {
                SettingsView()
            }
        }
    }
}

struct WelcomeView: View {
    let refresh: Bool
    @State private var hasAPIKey = false
    
    var body: some View {
        VStack(spacing: 24) {
            // API Key Warning Banner
            if !hasAPIKey {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.red)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("No API Key Set")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.red)
                            
                            Text("Go to Settings to add your OpenAI API key")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.red.opacity(0.1))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.red.opacity(0.3), lineWidth: 1)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            Image(systemName: "mic.fill")
                .font(.system(size: 64, weight: .medium))
                .foregroundStyle(.tint)
//                .symbolEffect(.pulse, options: .repeating)
            
            VStack(spacing: 8) {
                Text("Whisperer Keyboard")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text("Use the keyboard extension to record and transcribe audio")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            checkAPIKey()
        }
        .onChange(of: refresh) { _ in
            checkAPIKey()
        }
    }
    
    private func checkAPIKey() {
        hasAPIKey = KeychainHelper.shared.get("openai_api_key") != nil
    }
}

struct RecordingView: View {
    let audio: Audio
    @ObservedObject var transcription: Transcription
    @Binding var openedViaURLScheme: Bool
    @State private var powerLevel: Float = -80.0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 32) {
            // Sound visualizer (only show when recording)
            if transcription.status == .recording {
                SoundVisualizer(powerLevel: powerLevel)
                    .frame(height: 120)
                    .padding(.horizontal, 20)
            }
            
            // Transcription result display
            if transcription.status == .finished && !transcription.transcribedText.isEmpty {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("Transcription")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        Text("Return to the app to insert the transcribed text")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    ScrollView {
                        Text(transcription.transcribedText)
                            .font(.system(size: 17, weight: .regular))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                    }
                    .frame(maxHeight: 200)
                    .background {
                        if #available(iOS 26.0, *) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.1))
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Status button
            if transcription.status == .finished {
                VStack(spacing: 20) {
                    if #available(iOS 26.0, *) {
                        Button(action: handleButtonTap) {
                            HStack(spacing: 8) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("Re-record")
                                    .font(.system(size: 16, weight: .regular))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.glass)
                        
                        Button(action: handleClearTap) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("Clear")
                                    .font(.system(size: 16, weight: .regular))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.glass)
                        .tint(.red)
                    } else {
                        Button(action: handleButtonTap) {
                            HStack(spacing: 8) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("Re-record")
                                    .font(.system(size: 16, weight: .regular))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        
                        Button(action: handleClearTap) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("Clear")
                                    .font(.system(size: 16, weight: .regular))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
            } else {
                if #available(iOS 26.0, *) {
                    Button(action: handleButtonTap) {
                        HStack(spacing: 8) {
                            if transcription.status == .recording {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 16, weight: .medium))
                            } else if transcription.status == .transcribing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if transcription.status == .error {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            
                            Text(getButtonText())
                                .font(.system(size: 16, weight: .regular))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.glass)
                    .disabled(transcription.status == .transcribing)
                } else {
                    Button(action: handleButtonTap) {
                        HStack(spacing: 8) {
                            if transcription.status == .recording {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 16, weight: .medium))
                            } else if transcription.status == .transcribing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if transcription.status == .error {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            
                            Text(getButtonText())
                                .font(.system(size: 16, weight: .regular))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(transcription.status == .error ? .red : .blue)
                    .disabled(transcription.status == .transcribing)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 32)
        .onAppear {
            if transcription.status == .recording {
                startPowerLevelUpdates()
            }
        }
        .onChange(of: transcription.status) { newStatus in
            if newStatus == .recording {
                startPowerLevelUpdates()
            } else {
                stopPowerLevelUpdates()
            }
        }
        .onDisappear {
            stopPowerLevelUpdates()
        }
    }
    
    private func startPowerLevelUpdates() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            powerLevel = audio.getCurrentPowerLevel()
        }
    }
    
    private func stopPowerLevelUpdates() {
        timer?.invalidate()
        timer = nil
        powerLevel = -80.0
    }
    
    private func handleButtonTap() {
        if transcription.status == .recording {
            // Request to transcribe is what stops the audio recording
            audio.stop()
            transcription.transcribe(audio.getFilename())
        } else if transcription.status == .finished {
            // Re-record: reset state and start recording again
            transcription.status = .recording
            transcription.transcribedText = ""
            audio.start()
        } else if transcription.status == .error {
            // Retry on error
            transcription.status = .recording
            transcription.transcribedText = ""
            audio.start()
        }
    }
    
    private func handleClearTap() {
        // Clear transcribed text from both local state and shared storage
        transcription.transcribedText = ""
        transcription.sharedDefaults?.removeObject(forKey: "transcribedText")
        transcription.sharedDefaults?.synchronize()
        // Return to welcome screen with smooth animation
        withAnimation(.easeInOut(duration: 0.4)) {
            openedViaURLScheme = false
        }
    }
    
    private func getButtonText() -> String {
        switch transcription.status {
        case .recording:
            return "Stop Recording"
        case .transcribing:
            return "Transcribing..."
        case .finished:
            return "Re-record"
        case .error:
            return "Error - Try Again"
        }
    }
}

