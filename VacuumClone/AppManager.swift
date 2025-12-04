import Foundation
import SwiftUI

final class AppManager: ObservableObject {
    // Example published state for the menu app
    @Published var isRunning: Bool = false
    @Published var statusMessage: String = "Ready"

    // Example actions you can expand later
    func start() {
        isRunning = true
        statusMessage = "Running"
    }

    func stop() {
        isRunning = false
        statusMessage = "Stopped"
    }
}
