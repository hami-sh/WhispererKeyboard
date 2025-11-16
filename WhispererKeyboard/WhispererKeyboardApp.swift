//
//  WhispererKeyboardApp.swift
//  WhispererKeyboard
//
//  Created by Alexander Steshenko on 9/11/23.
//

import SwiftUI
import Foundation
import AVFAudio

// Shared app state that can be accessed from anywhere
class AppState: ObservableObject {
    static let shared = AppState()
    
    let audio = Audio()
    @Published var transcription = Transcription()
    
    private init() {
        print("[AppState] Initializing shared state")
        
        // Clear stale app_running flag from previous sessions
        TranscriptionBridge.shared.setAppRunning(false)
        print("[AppState] Cleared app_running flag from previous session")
        
        setupBackgroundListener()
    }
    
    private func setupBackgroundListener() {
        print("[AppState] Setting up background listener")
        let bridge = TranscriptionBridge.shared
        
        // Listen for audio ready notifications from keyboard
        bridge.addObserver(for: TranscriptionNotification.audioReady) {
            print("[AppState] ⚡️ Received audio ready notification from keyboard!")
            // Start recording in background
            DispatchQueue.main.async {
                print("[AppState] Starting new recording session")
                self.transcription.status = .recording
                self.transcription.transcribedText = "" // Clear previous transcription
                self.audio.start()
            }
        }
        print("[AppState] Background listener setup complete")
    }
}

/// This is a full screen view that opens up when "Record audio" button is clicked in the keyboard extension
/// When open, the app automatically begins recording. Once finished, the application requests transcriptiong using OpenAI Whisperer API
/// The app then suggests the user to return to the app that had the keyboard open. Unfortunately found no way to return user automatically.
@main
struct WhispererKeyboardApp: App {
    
    // Use shared app state
    @StateObject private var appState = AppState.shared
    
    // Necessary to detect when application becomes active
    @Environment(\.scenePhase) var scenePhase
    
    // Track whether we should show settings or recording view
    @State private var showSettings = false
    @State private var openedViaURLScheme = false
    
    init() {
        print("[App] WhispererKeyboardApp init() called")
    }
    
    var body: some Scene {
        // Will show one clickable text at at the bottom of the screen to control recording
        // Positioned at the bottom so it's convenient to swipe back to the previous app
        WindowGroup {
            ZStack {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    if openedViaURLScheme {
                        if appState.transcription.status == .finished && !appState.transcription.transcribedText.isEmpty {
                            VStack(spacing: 16) {
                                Text("Transcription:")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text(appState.transcription.transcribedText)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .padding()
                        }
                        
                        Text(getTranscriptionStatusMessage())
                            .onTapGesture(count: 1, perform: {
                                if appState.transcription.status != .finished {
                                    // Request to transcribe is what stops the audio recording
                                    appState.audio.stop()
                                    appState.transcription.transcribe(appState.audio.getFilename())
                                }
                            })
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.accentColor)
                            
                            Text("Whisperer Keyboard")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Use the keyboard extension to record and transcribe audio")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onOpenURL { url in
                print("[App] onOpenURL called with: \(url)")
                if url.scheme == "WhispererKeyboardApp" {
                    print("[App] Opening via URL scheme - first time setup")
                    openedViaURLScheme = true
                    appState.transcription.status = .recording
                    appState.transcription.transcribedText = ""
                    appState.audio.start()
                    
                    // Mark app as running for background communication
                    TranscriptionBridge.shared.setAppRunning(true)
                    print("[App] App marked as running in background")
                }
            }
            .onChange(of: scenePhase) { newPhase in
                print("[App] Scene phase changed to: \(newPhase)")
                if newPhase == .active && !openedViaURLScheme {
                    // Reset state when app comes to foreground normally
                    appState.transcription.status = .recording
                    appState.transcription.transcribedText = ""
                } else if newPhase == .background {
                    // Keep app marked as running in background (audio mode)
                    print("[App] ⚡️ Entering background - staying alive with audio mode")
                    print("[App] Audio session active: \(AVAudioSession.sharedInstance().category)")
                } else if newPhase == .inactive {
                    print("[App] Entering inactive state")
                    // Don't mark as not running - we want to stay alive
                }
            }
        }
    }
    
    func getTranscriptionStatusMessage() -> String {
        switch appState.transcription.status {
        case .recording:
            return "Press to stop recording"
        case .transcribing:
            return "Transcribing ..."
        case .finished:
            return "Finished. Return to the application"
        case .error:
            return "Error. Try again later"
        }
    }
}
