//
//  TranscriptionBridge.swift
//  WhispererKeyboard
//
//  Communication bridge between keyboard extension and main app using Darwin notifications
//

import Foundation

enum TranscriptionNotification {
    static let audioReady = "com.whisperer.audio.ready"
    static let transcriptionReady = "com.whisperer.transcription.ready"
    static let appRunning = "com.whisperer.app.running"
}

class TranscriptionBridge {
    static let shared = TranscriptionBridge()
    static let appGroupID = "group.HameboardSharing"
    
    private let userDefaults = UserDefaults(suiteName: appGroupID)
    
    private init() {}
    
    // MARK: - App Status
    
    func setAppRunning(_ running: Bool) {
        userDefaults?.set(running, forKey: "app_running")
        userDefaults?.synchronize()
        if running {
            postNotification(TranscriptionNotification.appRunning)
        }
    }
    
    func isAppRunning() -> Bool {
        return userDefaults?.bool(forKey: "app_running") ?? false
    }
    
    // MARK: - Audio File Management
    
    var sharedContainerURL: URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: TranscriptionBridge.appGroupID)
    }
    
    func getAudioFileURL() -> URL? {
        return sharedContainerURL?.appendingPathComponent("recording.m4a")
    }
    
    // MARK: - Darwin Notifications
    
    func postNotification(_ name: String) {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(rawValue: name as CFString),
            nil,
            nil,
            true
        )
        print("[Bridge] Posted notification: \(name)")
    }
    
    func addObserver(for name: String, callback: @escaping () -> Void) {
        let observer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            observer,
            { (_, observer, name, _, _) in
                if let observer = observer {
                    let bridge = Unmanaged<TranscriptionBridge>.fromOpaque(observer).takeUnretainedValue()
                    bridge.handleNotification(name: name?.rawValue as String? ?? "")
                }
            },
            name as CFString,
            nil,
            .deliverImmediately
        )
        
        // Store callback
        callbacks[name] = callback
        print("[Bridge] Added observer for: \(name)")
    }
    
    private var callbacks: [String: () -> Void] = [:]
    
    private func handleNotification(name: String) {
        print("[Bridge] Received notification: \(name)")
        callbacks[name]?()
    }
    
    // MARK: - Transcription Data
    
    func setTranscription(_ text: String) {
        userDefaults?.set(text, forKey: "transcribedText")
        userDefaults?.synchronize()
    }
    
    func getTranscription() -> String? {
        return userDefaults?.string(forKey: "transcribedText")
    }
    
    func clearTranscription() {
        userDefaults?.removeObject(forKey: "transcribedText")
        userDefaults?.synchronize()
    }
}
