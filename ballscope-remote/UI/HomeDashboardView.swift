import SwiftUI

struct HomeDashboardView: View {
    let isJetsonReachable: Bool
    let lastConnectionCheck: Date?
    let currentPath: String
    let pendingSystemAction: AppModel.SystemPowerAction?
    let systemPowerFeedback: AppModel.SystemPowerFeedback?
    let onOpenDestination: (AppDestination) -> Void
    let onSystemPowerAction: (AppModel.SystemPowerAction) -> Void
    let onOpenSettings: () -> Void

    @State private var confirmAction: AppModel.SystemPowerAction?
    @State private var showPowerConfirmation = false

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
                quickActions
                powerActions
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
        .confirmationDialog("System Power Action", isPresented: $showPowerConfirmation) {
            if let action = confirmAction {
                Button(action.title, role: .destructive) {
                    onSystemPowerAction(action)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let action = confirmAction {
                Text("This will \(action == .reboot ? "reboot" : "shut down") the BallScope device.")
            }
        }
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

    private var powerActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("System Power")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                powerCard(for: .reboot, tint: .orange)
                powerCard(for: .shutdown, tint: .red)
            }

            if let feedback = systemPowerFeedback {
                HStack(spacing: 8) {
                    Image(systemName: feedback.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    Text(feedback.message)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(2)
                }
                .foregroundStyle(feedback.isError ? .orange : .green)
                .padding(.horizontal, 4)
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Actions")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                actionCard(for: .record, tint: .red)
                actionCard(for: .analysis, tint: .blue)
                actionCard(for: .live, tint: .green)
            }
        }
    }

    private func powerCard(for action: AppModel.SystemPowerAction, tint: Color) -> some View {
        Button {
            confirmAction = action
            showPowerConfirmation = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if pendingSystemAction == action {
                        ProgressView()
                            .controlSize(.small)
                            .tint(tint)
                    } else {
                        Image(systemName: action.iconName)
                            .foregroundStyle(tint)
                    }
                    Spacer()
                }

                Text(action == .reboot ? "Reboot" : "Shutdown")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(tint.opacity(0.30), lineWidth: 1)
            }
            .opacity(isJetsonReachable ? 1 : 0.65)
        }
        .buttonStyle(.plain)
        .disabled(!isJetsonReachable || pendingSystemAction != nil)
    }

    private func actionCard(for destination: AppDestination, tint: Color) -> some View {
        Button {
            onOpenDestination(destination)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: destination.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)

                Text(destination.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(tint.opacity(0.28), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
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
