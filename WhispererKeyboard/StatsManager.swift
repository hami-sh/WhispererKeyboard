//
//  StatsManager.swift
//  WhispererKeyboard
//
//  Created for tracking app usage statistics
//

import Foundation

/// Manages local statistics tracking for the app
/// Stores data locally on the device using UserDefaults
class StatsManager {
    static let shared = StatsManager()
    
    private let sharedDefaults = UserDefaults(suiteName: "group.HameboardSharing")
    
    // Keys for storing stats
    private let transcriptionCountKey = "stats_transcription_count"
    private let wordCountKey = "stats_word_count"
    
    private init() {}
    
    /// Increment the transcription invocation count
    func incrementTranscriptionCount() {
        let currentCount = getTranscriptionCount()
        sharedDefaults?.set(currentCount + 1, forKey: transcriptionCountKey)
        sharedDefaults?.synchronize()
    }
    
    /// Get the total number of transcription invocations
    func getTranscriptionCount() -> Int {
        return sharedDefaults?.integer(forKey: transcriptionCountKey) ?? 0
    }
    
    /// Add words to the total word count
    /// - Parameter text: The text to count words from
    func addWordsFromText(_ text: String) {
        let wordCount = countWords(in: text)
        let currentTotal = getWordCount()
        sharedDefaults?.set(currentTotal + wordCount, forKey: wordCountKey)
        sharedDefaults?.synchronize()
    }
    
    /// Get the total number of words typed
    func getWordCount() -> Int {
        return sharedDefaults?.integer(forKey: wordCountKey) ?? 0
    }
    
    /// Count words in a given text string
    /// - Parameter text: The text to count words in
    /// - Returns: The number of words
    private func countWords(in text: String) -> Int {
        let components = text.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.count
    }
    
    /// Reset all statistics (useful for testing or user preference)
    func resetStats() {
        sharedDefaults?.removeObject(forKey: transcriptionCountKey)
        sharedDefaults?.removeObject(forKey: wordCountKey)
        sharedDefaults?.synchronize()
    }
}

