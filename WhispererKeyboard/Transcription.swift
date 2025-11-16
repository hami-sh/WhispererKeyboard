//
//  Transcription.swift
//  WhispererKeyboard
//
//  Created by Alexander Steshenko on 10/2/23.
//

import Foundation


/// Perform transcription of a given audio file using OpenAI GPT-4o Transcribe API
/// Results are stored in shared group.HameboardSharing storage
///
/// Maintains internal "status" property to show status of transcription, useful when transcription takes a few seconds
///
class Transcription : ObservableObject {

    enum TranscriptionStatus {
        case recording
        case transcribing
        case finished
        case error
    }
    
    // Default status, before transcription is called audio is recorded
    @Published var status: TranscriptionStatus = .recording
    
    // Store the transcribed text for display
    @Published var transcribedText: String = ""
    
    // This shared container is necessary to pass data between the main app and the keyboard extension
    // Since it's not possible to access microphone from within the keyboard itself
    let sharedDefaults = UserDefaults(suiteName: "group.HameboardSharing")
    
    func transcribe(_ audioFilename : URL) {
        guard let apiKey = KeychainHelper.shared.get("openai_api_key"), !apiKey.isEmpty else {
            print("No API key found in Keychain")
            DispatchQueue.main.async {
                self.status = .error
            }
            return
        }
        
        self.status = .transcribing
        do {
            sendRequestToOpenAI(file: try Data(contentsOf: audioFilename), apiKey: apiKey) {
                (result:Result<String, Error>) in
                switch result {
                case .success(let text):
                    // On successful transcription using OpenAI Whisperer, store the results into shared storage
                    // so that the Keyboard extension can find it and insert into the application under edit
                    self.sharedDefaults?.set(text, forKey: "transcribedText")
                    DispatchQueue.main.async {
                        self.transcribedText = text
                    }
                case .failure(let failure):
                    print("\(failure.localizedDescription)")
                }
                DispatchQueue.main.async {
                    self.status = .finished
                }
            }
        } catch {
            print(error)
            status = .error
            return
        }
    }
    
    struct WhispererResponse: Codable {
        public let text: String
    }
    
    func sendRequestToOpenAI(file: Data, apiKey: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("gzip", forHTTPHeaderField: "Accept-Encoding")

        // Audio file is sent to OpenAI as multipart form data. There is probably an easier way to do this with a built-in library
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var formData = Data()
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
        formData.append("\r\n".data(using: .utf8)!)
        formData.append(file)
        formData.append("\r\n".data(using: .utf8)!)
        
        // This specifies the model to use "gpt-4o-transcribe"
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"model\"\r\n\r\ngpt-4o-transcribe\r\n".data(using: .utf8)!)
        
        // Add prompt with custom vocabulary if available
        if let prompt = generatePromptWithVocabulary() {
            formData.append("--\(boundary)\r\n".data(using: .utf8)!)
            formData.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n\(prompt)\r\n".data(using: .utf8)!)
        }
        
        formData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = formData
        
        // Below makes the http request and passes the resulting text to the callback function
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("API request error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                let noDataError = NSError(domain: "Transcription", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received from API"])
                completion(.failure(noDataError))
                return
            }
            
            // Log response for debugging
            if let httpResponse = response as? HTTPURLResponse {
                print("API response status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("API error response: \(errorString)")
                    }
                }
            }
            
            do {
                let response = try JSONDecoder().decode(WhispererResponse.self, from: data)
                completion(.success(response.text))
            } catch let decodingError {
                // Log the raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Failed to decode response. Raw response: \(responseString)")
                }
                completion(.failure(decodingError))
            }
        }
        task.resume()
    }
    
    // MARK: - Custom Vocabulary Management
    
    /// Load custom vocabulary from UserDefaults
    private func loadCustomVocabulary() -> [String]? {
        guard let sharedDefaults = sharedDefaults,
              let vocabularyData = sharedDefaults.data(forKey: "custom_vocabulary"),
              let vocabulary = try? JSONDecoder().decode([String].self, from: vocabularyData) else {
            return nil
        }
        return vocabulary.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
    
    /// Generate a prompt string that includes custom vocabulary terms
    private func generatePromptWithVocabulary() -> String? {
        guard let vocabulary = loadCustomVocabulary(), !vocabulary.isEmpty else {
            return nil
        }
        
        // Format vocabulary list
        let vocabularyList: String
        if vocabulary.count == 1 {
            vocabularyList = vocabulary[0]
        } else if vocabulary.count == 2 {
            vocabularyList = "\(vocabulary[0]) and \(vocabulary[1])"
        } else {
            let allButLast = vocabulary.dropLast().joined(separator: ", ")
            vocabularyList = "\(allButLast), and \(vocabulary.last!)"
        }
        
        // Create prompt with context about specialized terms
        return "The following specialized terms are commonly used in this recording: \(vocabularyList)."
    }
    
    /// Save custom vocabulary to UserDefaults
    static func saveCustomVocabulary(_ vocabulary: [String]) {
        let sharedDefaults = UserDefaults(suiteName: "group.HameboardSharing")
        if let vocabularyData = try? JSONEncoder().encode(vocabulary) {
            sharedDefaults?.set(vocabularyData, forKey: "custom_vocabulary")
            sharedDefaults?.synchronize()
        }
    }
    
    /// Get custom vocabulary from UserDefaults
    static func getCustomVocabulary() -> [String] {
        let sharedDefaults = UserDefaults(suiteName: "group.HameboardSharing")
        guard let vocabularyData = sharedDefaults?.data(forKey: "custom_vocabulary"),
              let vocabulary = try? JSONDecoder().decode([String].self, from: vocabularyData) else {
            return []
        }
        return vocabulary
    }
}
