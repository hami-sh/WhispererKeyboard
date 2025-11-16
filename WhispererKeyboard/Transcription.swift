//
//  Transcription.swift
//  WhispererKeyboard
//
//  Created by Alexander Steshenko on 10/2/23.
//

import Foundation


/// Perform transcription of a given audio file using OpenAI Whisperer API
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
        print("[Transcription] transcribe() called with file: \(audioFilename)")
        guard let apiKey = KeychainHelper.shared.get("openai_api_key"), !apiKey.isEmpty else {
            print("[Transcription] ERROR: No API key found in Keychain")
            DispatchQueue.main.async {
                self.status = .error
            }
            return
        }
        
        self.status = .transcribing
        print("[Transcription] Status set to transcribing")
        do {
            let audioData = try Data(contentsOf: audioFilename)
            print("[Transcription] Audio file loaded, size: \(audioData.count) bytes")
            sendRequestToOpenAI(file: audioData, apiKey: apiKey) {
                (result:Result<String, Error>) in
                switch result {
                case .success(let text):
                    print("[Transcription] ✅ Success! Text: \(text)")
                    // On successful transcription using OpenAI Whisperer, store the results into shared storage
                    // so that the Keyboard extension can find it and insert into the application under edit
                    self.sharedDefaults?.set(text, forKey: "transcribedText")
                    print("[Transcription] Saved to shared defaults")
                    DispatchQueue.main.async {
                        self.transcribedText = text
                    }
                case .failure(let failure):
                    print("[Transcription] ERROR: \(failure.localizedDescription)")
                }
                DispatchQueue.main.async {
                    self.status = .finished
                    print("[Transcription] Status set to finished")
                }
            }
        } catch {
            print("[Transcription] ERROR loading audio file: \(error)")
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
        
        // This specifies the model to use "whisper-1"
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"model\"\r\n\r\nwhisper-1\r\n".data(using: .utf8)!)
        
        formData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = formData
        
        // Below makes the http request and passes the resulting text to the callback function
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            do {
                let response = try JSONDecoder().decode(WhispererResponse.self, from: data!)
                completion(.success(response.text))
            } catch let decodingError {
                
                completion(.failure(decodingError))
            }
        }
        task.resume()
    }
}
