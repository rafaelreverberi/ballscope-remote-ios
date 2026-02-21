import SwiftUI

struct LiquidTabBar: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var selectedDestination: AppDestination
    let onSelection: (AppDestination) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(AppDestination.allCases) { destination in
                Button {
                    onSelection(destination)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: destination.iconName)
                            .font(.system(size: 15, weight: .semibold))
                        Text(destination.title)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(selectedDestination == destination ? activeForeground : inactiveForeground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(selectedDestination == destination ? activeBackground : Color.clear)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    private var activeForeground: Color {
        colorScheme == .dark ? .white : .primary
    }

    private var inactiveForeground: Color {
        colorScheme == .dark ? .white.opacity(0.72) : .secondary
    }

    private var activeBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.20) : Color.primary.opacity(0.10)
    }
}
