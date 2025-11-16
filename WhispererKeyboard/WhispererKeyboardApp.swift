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
    @State private var showHelp = false
    @State private var showStats = false
    @State private var openedViaURLScheme = false
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                audio: audio,
                transcription: transcription,
                showSettings: $showSettings,
                showHelp: $showHelp,
                showStats: $showStats,
                openedViaURLScheme: $openedViaURLScheme
            )
            .onOpenURL { url in
                if url.scheme == "WhispererKeyboardApp" {
                    if url.host == "help" {
                        showHelp = true
                    } else {
                        openedViaURLScheme = true
                        transcription.status = .recording
                        audio.start()
                    }
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
    @Binding var showHelp: Bool
    @Binding var showStats: Bool
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
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showStats = true }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 18, weight: .medium))
                    }
                    
                    Button(action: { showHelp = true }) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                    }
                    
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
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
            .sheet(isPresented: $showStats) {
                StatsView()
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
            // Track transcription invocation
            StatsManager.shared.incrementTranscriptionCount()
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

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Getting Started Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Getting Started")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HelpStep(number: "1", text: "Add the Whisperer Keyboard to your device")
                            HelpStep(number: "2", text: "Go to Settings → Keyboard → Add New Keyboard → Whisperer Keyboard")
                            HelpStep(number: "3", text: "Enable \"Allow Full Access\" (required for transcription)")
                            HelpStep(number: "4", text: "Open this app and add your OpenAI API key in Settings")
                            HelpStep(number: "5", text: "Start using the keyboard in any app!")
                        }
                    }
                    
                    // How to Use Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to Use")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HelpFeature(
                                icon: "mic.fill",
                                title: "Record Button",
                                description: "Tap the Record button to start recording audio. The app will open automatically and begin transcribing your speech."
                            )
                            
                            HelpFeature(
                                icon: "return",
                                title: "Return Button",
                                description: "Inserts a new line in your text field, just like the standard keyboard."
                            )
                            
                            HelpFeature(
                                icon: "delete.backward",
                                title: "Backspace Button",
                                description: "Deletes the character before the cursor, just like the standard keyboard."
                            )
                            
                            HelpFeature(
                                icon: "questionmark.circle",
                                title: "Help Button",
                                description: "Tap this button anytime to view help and instructions."
                            )
                        }
                    }
                    
                    // Tips Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tips")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TipItem(text: "Speak clearly and at a normal pace for best results")
                            TipItem(text: "Add custom vocabulary words in Settings to improve accuracy")
                            TipItem(text: "The transcribed text will automatically appear when you return to your app")
                            TipItem(text: "You can re-record if the transcription isn't accurate")
                        }
                    }
                    
                    // Troubleshooting Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Troubleshooting")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            TroubleshootingItem(
                                question: "The keyboard doesn't appear",
                                answer: "Make sure you've added the keyboard in Settings and enabled it in your keyboard list."
                            )
                            
                            TroubleshootingItem(
                                question: "Recording doesn't start",
                                answer: "Check that you've granted microphone permissions and added your OpenAI API key in Settings."
                            )
                            
                            TroubleshootingItem(
                                question: "Transcription is inaccurate",
                                answer: "Try speaking more clearly, add custom vocabulary words, or check your internet connection."
                            )
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Help")
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
    }
}

struct HelpStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background {
                    Circle()
                        .fill(.blue)
                }
            
            Text(text)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct HelpFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

struct TipItem: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.yellow)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct TroubleshootingItem: View {
    let question: String
    let answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.orange)
                    .frame(width: 20)
                
                Text(question)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            Text(answer)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.secondary)
                .padding(.leading, 28)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}


