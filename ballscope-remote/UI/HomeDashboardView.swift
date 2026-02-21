import SwiftUI

struct HomeDashboardView: View {
    let isJetsonReachable: Bool
    let lastConnectionCheck: Date?
    let currentPath: String
    let onOpenSettings: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("BallScope Remote")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Control your Jetson directly from iPhone with a native interface.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)

                statusCard
                statsGrid

                Button(action: onOpenSettings) {
                    HStack(spacing: 10) {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.20), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
            }
            .padding(20)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(isJetsonReachable ? Color.green : Color.orange)
                    .frame(width: 11, height: 11)
                Text(isJetsonReachable ? "Jetson reachable" : "Jetson unreachable")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }

            Text(isJetsonReachable ? "Open Record, Analysis, or Live instantly." : "Connect to the Jetson Wi-Fi network and try again.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        }
    }

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statTile(
                title: "Route",
                value: currentPath,
                symbol: "network"
            )

            statTile(
                title: "Last Check",
                value: lastConnectionCheck?.formatted(date: .omitted, time: .shortened) ?? "-",
                symbol: "clock.fill"
            )
        }
    }

    private func statTile(title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        }
    }
}
