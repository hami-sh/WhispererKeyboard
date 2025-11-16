import SwiftUI
struct KeyboardView: View {
    let onRecordTap: () -> Void
    let onReturnTap: () -> Void
    let onBackspaceTap: () -> Void
    let onHelpTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main centered content
            VStack(spacing: 8) {
                // Record button (primary)
                if #available(iOS 26.0, *) {
                    Button(action: onRecordTap) {
                        HStack(spacing: 8) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 16))
                            Text("Record")
                                .font(.system(size: 16, weight: .regular))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.glass)
                    .tint(.blue)
                } else {
                    Button(action: onRecordTap) {
                        HStack(spacing: 8) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 16))
                            Text("Record")
                                .font(.system(size: 16, weight: .regular))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }

                // Return and Backspace buttons
                HStack(spacing: 8) {
                    if #available(iOS 26.0, *) {
                        Button(action: onReturnTap) {
                            Image(systemName: "return")
                                .font(.system(size: 16, weight: .regular))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.glass)
                        
                        Button(action: onBackspaceTap) {
                            Image(systemName: "delete.backward")
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
                        
                        Button(action: onBackspaceTap) {
                            Image(systemName: "delete.backward")
                                .font(.system(size: 16, weight: .regular))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Help button anchored to bottom right (outside centered content)
            if #available(iOS 26.0, *) {
                Button(action: onHelpTap) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 16, weight: .regular))
                        .padding(5)
                }
                .buttonStyle(.glass)
                .clipShape(Circle())
            } else {
                Button(action: onHelpTap) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 16, weight: .regular))
                        .padding(5)
                }
                .buttonStyle(.bordered)
                .clipShape(Circle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.clear)
    }
}
