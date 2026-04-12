import SwiftUI

// MARK: - Content View

struct ContentView: View {
    @StateObject private var viewModel = StoryViewModel()
    @State private var characters = ""
    @State private var moral = ""
    @State private var duration: StoryDuration = .medium
    @FocusState private var activeField: ActiveField?

    var body: some View {
        ZStack {
            NightSkyBackground()
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        HeaderSection()

                        formCard

                        generateButton

                        if let err = viewModel.errorMessage {
                            ErrorBanner(message: err)
                                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        }

                        if !viewModel.story.isEmpty {
                            StoryCard(viewModel: viewModel)
                                .id("story")
                                .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
                        }

                        Spacer().frame(height: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                .onChange(of: viewModel.story) { newStory in
                    guard !newStory.isEmpty else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) {
                            proxy.scrollTo("story", anchor: .top)
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: viewModel.story.isEmpty)
        .animation(.easeOut(duration: 0.25), value: viewModel.errorMessage)
        .onTapGesture { activeField = nil }
    }

    // MARK: - Form Card

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            inputField(
                label: "Characters",
                icon: "sparkles",
                placeholder: "e.g. Luna the bunny, Max the bear",
                text: $characters,
                field: .characters
            )

            sectionDivider

            inputField(
                label: "Moral of the Story",
                icon: "heart.fill",
                placeholder: "e.g. Sharing brings joy to everyone",
                text: $moral,
                field: .moral
            )

            sectionDivider

            durationPicker
        }
        .padding(22)
        .background(Theme.cardBackground.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Theme.cardBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func inputField(
        label: String,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: ActiveField
    ) -> some View {
        let focused = activeField == field
        VStack(alignment: .leading, spacing: 10) {
            Label(label, systemImage: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.lavender)
                .textCase(.uppercase)
                .tracking(1.2)

            TextField("", text: text, prompt:
                Text(placeholder).foregroundColor(Theme.lavender.opacity(0.45))
            )
            .font(.system(size: 16))
            .foregroundColor(Theme.starWhite)
            .focused($activeField, equals: field)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(focused ? 0.09 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        focused ? Theme.accentPurple.opacity(0.8) : Theme.cardBorder,
                        lineWidth: 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: focused)
        }
    }

    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Story Length", systemImage: "moon.stars.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.lavender)
                .textCase(.uppercase)
                .tracking(1.2)

            HStack(spacing: 10) {
                ForEach(StoryDuration.allCases) { dur in
                    DurationChip(duration: dur, isSelected: duration == dur) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            duration = dur
                        }
                    }
                }
            }
        }
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Theme.divider)
            .frame(height: 1)
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        let isEmpty = characters.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let disabled = isEmpty || viewModel.isLoading

        return Button {
            activeField = nil
            Task {
                await viewModel.generateStory(
                    characters: characters,
                    moral: moral,
                    duration: duration.rawValue
                )
            }
        } label: {
            HStack(spacing: 10) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Theme.buttonText)
                        .scaleEffect(0.85)
                    Text("Weaving your story…")
                } else {
                    Image(systemName: "wand.and.stars")
                    Text("Weave the Story")
                }
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(Theme.buttonText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(disabled ? Theme.moonYellow.opacity(0.40) : Theme.moonYellow)
            )
        }
        .disabled(disabled)
    }
}

// MARK: - Night Sky Background

struct NightSkyBackground: View {
    private struct Star {
        let x, y, radius, opacity: CGFloat
    }

    // Fixed seed gives a consistent, reproducible starfield every time
    private static let stars: [Star] = {
        var result = [Star]()
        var seed: UInt64 = 98_765_432_101

        for _ in 0..<320 {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let x = CGFloat(seed >> 33) / 2_147_483_648.0
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let y = CGFloat(seed >> 33) / 2_147_483_648.0
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let r = CGFloat(seed >> 33) / 2_147_483_648.0 * 1.7 + 0.3
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let o = CGFloat(seed >> 33) / 2_147_483_648.0 * 0.55 + 0.25
            result.append(Star(x: x, y: y, radius: r, opacity: o))
        }
        return result
    }()

    var body: some View {
        Canvas { ctx, size in
            // Deep space gradient
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: Color(hex: "#07051A"), location: 0.0),
                        .init(color: Color(hex: "#0F062C"), location: 0.45),
                        .init(color: Color(hex: "#1A0A3E"), location: 1.0),
                    ]),
                    startPoint: CGPoint(x: size.width * 0.5, y: 0),
                    endPoint:   CGPoint(x: size.width * 0.5, y: size.height)
                )
            )

            // Purple nebula glow — top-right corner
            ctx.fill(
                Path(ellipseIn: CGRect(
                    x: size.width * 0.25,
                    y: -size.height * 0.2,
                    width: size.width * 1.1,
                    height: size.height * 0.65
                )),
                with: .color(Color(hex: "#6B21A8").opacity(0.08))
            )

            // Blue-indigo nebula — bottom-left
            ctx.fill(
                Path(ellipseIn: CGRect(
                    x: -size.width * 0.3,
                    y: size.height * 0.55,
                    width: size.width * 0.9,
                    height: size.height * 0.6
                )),
                with: .color(Color(hex: "#1E3A8A").opacity(0.06))
            )

            // Stars
            for star in Self.stars {
                let r = star.radius
                ctx.fill(
                    Path(ellipseIn: CGRect(
                        x: star.x * size.width  - r,
                        y: star.y * size.height - r,
                        width:  r * 2,
                        height: r * 2
                    )),
                    with: .color(.white.opacity(star.opacity))
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Header Section

struct HeaderSection: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 54))
                .foregroundStyle(Theme.moonYellow, Theme.lavender)
                .padding(.bottom, 4)

            Text("Hushling")
                .font(.custom("Georgia-Bold", size: 36))
                .foregroundColor(Theme.moonYellow)

            Text("A bedtime story crafted just for you")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(Theme.lavender)
                .padding(.top, 6)
        }
        .multilineTextAlignment(.center)
        .padding(.top, 28)
    }
}

// MARK: - Duration Chip

struct DurationChip: View {
    let duration: StoryDuration
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: duration.icon)
                    .font(.system(size: 17))
                Text(duration.label)
                    .font(.system(size: 14, weight: .semibold))
                Text(duration.subtitle)
                    .font(.system(size: 11))
                    .opacity(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .foregroundColor(isSelected ? Theme.buttonText : Theme.lavender)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Theme.moonYellow : Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? Theme.moonYellow : Theme.cardBorder,
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .padding(.top, 1)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Theme.starWhite.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.orange.opacity(0.30), lineWidth: 1)
        )
    }
}

// MARK: - Story Card

struct StoryCard: View {
    @ObservedObject var viewModel: StoryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Card header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "book.pages.fill")
                        .foregroundColor(Theme.moonYellow)
                    Text("Your Story")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.lavender)
                        .textCase(.uppercase)
                        .tracking(1.2)
                }
                Spacer()
                // Read Aloud icon button
                Button { viewModel.toggleSpeech() } label: {
                    ZStack {
                        Circle()
                            .fill(viewModel.isSpeaking
                                  ? Theme.moonYellow
                                  : Theme.moonYellow.opacity(0.12))
                            .frame(width: 34, height: 34)
                        Image(systemName: viewModel.isSpeaking ? "stop.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(viewModel.isSpeaking ? Theme.buttonText : Theme.moonYellow)
                    }
                }
                .overlay(
                    Circle()
                        .strokeBorder(Theme.moonYellow.opacity(0.35), lineWidth: 1)
                        .frame(width: 34, height: 34)
                )
            }

            Rectangle()
                .fill(Theme.divider)
                .frame(height: 1)

            // Story text
            Text(viewModel.story)
                .font(.custom("Georgia", size: 17))
                .foregroundColor(Theme.starWhite)
                .lineSpacing(8)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

        }
        .padding(22)
        .background(Theme.cardBackground.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Theme.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Speaking Wave Animation

struct SpeakingWaveView: View {
    @State private var animating = false

    private let heights: [[CGFloat]] = [
        [5, 12, 7, 15, 9],
        [10, 6, 14, 8, 13],
    ]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.buttonText)
                    .frame(width: 3, height: animating ? heights[1][i] : heights[0][i])
                    .animation(
                        .easeInOut(duration: 0.38)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.08),
                        value: animating
                    )
            }
        }
        .frame(height: 18)
        .onAppear  { animating = true  }
        .onDisappear { animating = false }
    }
}
