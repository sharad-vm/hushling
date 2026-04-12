import Foundation
import AVFoundation
import Combine

// MARK: - Speech Delegate Shim
// A plain NSObject delegate that forwards events back to the ViewModel via a closure.
// This avoids the @MainActor + NSObject + ObservableObject conformance conflict.
private class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onFinish: (() -> Void)?

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        onFinish?()
    }
}

// MARK: - Story ViewModel

@MainActor
class StoryViewModel: ObservableObject {
    @Published var story: String = ""
    @Published var isLoading: Bool = false
    @Published var isSpeaking: Bool = false
    @Published var errorMessage: String?

    private let synthesizer = AVSpeechSynthesizer()
    private let speechDelegate = SpeechDelegate()

    init() {
        synthesizer.delegate = speechDelegate
        speechDelegate.onFinish = { [weak self] in
            Task { @MainActor [weak self] in
                self?.isSpeaking = false
            }
        }
    }

    // MARK: - Story Generation

    func generateStory(characters: String, moral: String, duration: String) async {
        let trimmed = characters.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter at least one character."
            return
        }

        isLoading = true
        errorMessage = nil
        stopSpeaking()
        story = ""

        do {
            story = try await APIService.shared.generateStory(
                characters: characters,
                moral: moral,
                duration: duration
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Text-to-Speech

    func toggleSpeech() {
        isSpeaking ? stopSpeaking() : startSpeaking()
    }

    private func startSpeaking() {
        guard !story.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: story)
        utterance.rate            = 0.40   // slow and soothing
        utterance.pitchMultiplier = 1.05   // slightly warm pitch
        utterance.volume          = 0.95
        utterance.voice           = preferredVoice()

        synthesizer.speak(utterance)
        isSpeaking = true
    }

    func stopSpeaking() {
        guard synthesizer.isSpeaking || synthesizer.isPaused else { return }
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    private func preferredVoice() -> AVSpeechSynthesisVoice? {
        // Priority order — warmest/most natural first.
        // Premium voices must be downloaded on-device:
        //   Settings → Accessibility → Spoken Content → Voices → English
        // "Nicky" and "Evan" (premium) are the closest to ASMR/warm narrator quality.
        let candidates = [
            "com.apple.voice.premium.en-US.Nicky",      // warm, soft female — best for bedtime
            "com.apple.voice.premium.en-US.Evan",       // calm, gentle male
            "com.apple.voice.premium.en-IE.Moira",      // soft Irish female
            "com.apple.voice.premium.en-GB.Martha",     // gentle British female
            "com.apple.voice.enhanced.en-US.Nicky",     // enhanced fallback
            "com.apple.voice.enhanced.en-US.Samantha",
            "com.apple.ttsbundle.Samantha-premium",
            "com.apple.voice.enhanced.en-GB.Martha",
            "com.apple.voice.enhanced.en-AU.Karen",
        ]
        for id in candidates {
            if let voice = AVSpeechSynthesisVoice(identifier: id) {
                return voice
            }
        }
        return AVSpeechSynthesisVoice(language: "en-US")
    }
}
