//
//  Audio.swift
//  WhispererKeyboard
//
//  Created by Alexander Steshenko on 10/2/23.
//

import Foundation
import AVFoundation


/// Records audio from microphone to a predefine file "recording.m4a".
/// To get file name use function getFilename
/// Use start() and stop() to operate the recorder
class Audio {
    var recorder: AVAudioRecorder?
    
    class AudioRecorderDelegate: NSObject, AVAudioRecorderDelegate {
        var onError: ((Error?) -> Void)?
        
        func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
            onError?(error)
        }
    }
    
    private let audioRecorderDelegate = AudioRecorderDelegate()
    
    let audioSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    
    func stop() {
        print("[Audio] stop() called, isRecording: \(recorder?.isRecording ?? false)")
        recorder?.stop()
        
        // DON'T deactivate audio session - we want to stay alive in background
        // for subsequent recordings without reopening the app
        print("[Audio] Recording stopped - keeping audio session active for background mode")
    }
    
    func start() {
        print("[Audio] start() called")
        requestMicrophonePermission() // only requests permissions if not previously granted
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Use .record category to enable background audio recording
            // This allows the app to stay alive in background while recording
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
            print("[Audio] Audio session activated for background recording")
        } catch {
            print("[Audio] ERROR: Failed to set up audio session: \(error)")
            return
        }
        
        do {
            recorder = try AVAudioRecorder(url: getFilename(), settings: audioSettings)
            recorder?.delegate = audioRecorderDelegate
            recorder?.record()
            print("[Audio] Recording started - app will stay alive in background")
        } catch {
            print("[Audio] ERROR: Could not start recording: \(error)")
        }
    }
    
    func getFilename() -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("recording.m4a")
    }
    
    func requestMicrophonePermission() {
        let audioSession = AVAudioSession.sharedInstance()
        
        switch audioSession.recordPermission {
        case .granted:
            // Microphone permission already granted
            break
        case .denied:
            print("Microphone access has been denied.")
        case .undetermined:
            audioSession.requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    if !allowed {
                        // Handle the denial.
                        print("Microphone access was denied.")
                    }
                }
            }
        @unknown default:
            print("Unknown microphone access status.")
        }
    }
}
