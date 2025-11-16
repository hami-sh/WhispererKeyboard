//
//  KeyboardViewController.swift
//  keyboard
//
//  Created by Alexander Steshenko on 9/11/23.
//

import UIKit
import SwiftUI

/// Custom keyboard view. This keyboard only has one button in the center which begins recording once pressed
/// Recording is performed by the main app "WhispererKeyboardApp" immediately when it opens
/// After recording is processed by OpenAI, the keyboard inserts the text into the text edit field that is in focus
class KeyboardViewController: UIInputViewController {
    
    private var keyboardHeight: CGFloat = 155
    private let sharedDefaults = UserDefaults(suiteName: "group.HameboardSharing")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("[Keyboard] viewDidLoad called")
        
        // Make the main view background transparent
        view.backgroundColor = .clear
        
        let keyboardView = KeyboardView(
            onRecordTap: { [weak self] in
                self?.handleRecordTap()
            },
            onReturnTap: { [weak self] in
                self?.handleReturnTap()
            }
        )
        
        let hostingController = UIHostingController(rootView: keyboardView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        // Make the hosting controller's view background transparent
        hostingController.view.backgroundColor = .clear
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.heightAnchor.constraint(equalToConstant: keyboardHeight)
        ])
        
        print("[Keyboard] SwiftUI view setup complete")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("[Keyboard] viewDidAppear called")
        
        if let transcribedText = sharedDefaults?.string(forKey: "transcribedText") {
            print("[Keyboard] Found transcribed text: \(transcribedText)")
            textDocumentProxy.insertText(transcribedText)
            sharedDefaults?.removeObject(forKey: "transcribedText")
            print("[Keyboard] Text inserted and cleared from shared defaults")
        } else {
            print("[Keyboard] No transcribed text found in shared defaults")
        }
    }
    
    private func handleRecordTap() {
        print("[Keyboard] Record button tapped")
        
        guard let url = URL(string: "WhispererKeyboardApp://") else {
            print("[Keyboard] ERROR: Failed to create URL")
            return
        }
        
        print("[Keyboard] Attempting to open URL: \(url)")
        openURL(url)
    }
    
    private func handleReturnTap() {
        print("[Keyboard] Return button tapped")
        textDocumentProxy.insertText("\n")
    }
    
    @discardableResult
    private func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                print("[Keyboard] Found UIApplication, calling open()")
                application.open(url, options: [:]) { success in
                    if success {
                        print("[Keyboard] Successfully opened main app")
                    } else {
                        print("[Keyboard] Failed to open URL - check URL scheme registration")
                    }
                }
                return true
            }
            responder = responder?.next
        }
        print("[Keyboard] ERROR: Could not find UIApplication in responder chain")
        return false
    }
}

struct KeyboardView: View {
    let onRecordTap: () -> Void
    let onReturnTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            if #available(iOS 26.0, *) {
                Button(action: onRecordTap) {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16))
                        Text("Record")
                            .font(.system(size: 16, weight: .regular))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.glass)
            } else {
                Button(action: onRecordTap) {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16))
                        Text("Record")
                            .font(.system(size: 16, weight: .regular))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .foregroundColor(.white)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }

            if #available(iOS 26.0, *) {
                Button(action: onReturnTap) {
                    Image(systemName: "return")
                        .font(.system(size: 16, weight: .regular))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.glass)
            } else {
                Button(action: onReturnTap) {
                    Image(systemName: "return")
                        .font(.system(size: 16, weight: .regular))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.clear)
    }
}
