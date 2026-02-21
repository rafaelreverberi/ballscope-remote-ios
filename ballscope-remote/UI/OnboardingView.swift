import SwiftUI

struct OnboardingView: View {
    let onContinue: () -> Void

    @State private var step = 0

    var body: some View {
        ZStack {
            LiquidBackground()

            VStack(spacing: 20) {
                TabView(selection: $step) {
                    introStep.tag(0)
                    wifiStep.tag(1)
                    doneStep.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .interactive))
            }
            .padding(18)
        }
        .interactiveDismissDisabled(true)
    }

    private var introStep: some View {
        card {
            Image(systemName: "sparkles")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.cyan)

            Text("Welcome to BallScope Remote")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Text("Use quick native controls while Jetson handles recording, analysis, and live stream in the background.")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Next") {
                withAnimation { step = 1 }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var wifiStep: some View {
        card {
            Image(systemName: "wifi")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.mint)

            Text("Secure Connection Setup")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Text("Always connect your iPhone to the BallScope Wi-Fi before using the app. This keeps the connection stable and secure with your device.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)

            VStack(alignment: .leading, spacing: 10) {
                setupHint("Open iOS Wi-Fi settings")
                setupHint("Select the network named BallScope")
                setupHint("Return to BallScope Remote and continue")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.10), lineWidth: 1)
            }

            Button("Continue") {
                withAnimation { step = 2 }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var doneStep: some View {
        card {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.green)

            Text("You're ready")
                .font(.system(size: 30, weight: .bold, design: .rounded))

            Text("If Jetson is online on `jetson.local:8000`, jump into Record, Analysis, or Live from the Home shortcuts.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Start Using App") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 14) {
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        }
    }

    private func setupHint(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
        }
    }
}
