import SwiftUI
import AVFoundation

@main
struct HushlingApp: App {

    init() {
        setupAudioSession()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }

    private func setupAudioSession() {
        // AVAudioSession is iOS-only; macOS manages audio routing automatically
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers, .allowBluetooth]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error.localizedDescription)")
        }
        #endif
    }
}
