import SwiftUI

// Simple preview for KeyboardView without code duplication
#Preview {
    KeyboardView(
        onRecordTap: { print("Record tapped") },
        onReturnTap: { print("Return tapped") },
        onBackspaceTap: { print("Backspace tapped") },
        onHelpTap: { print("Help tapped") }
    )
    .frame(height: 200)
}
