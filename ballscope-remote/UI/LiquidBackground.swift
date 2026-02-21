import SwiftUI

struct LiquidBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.cyan.opacity(colorScheme == .dark ? 0.23 : 0.16))
                .frame(width: 380)
                .blur(radius: 36)
                .offset(x: -140, y: -230)

            RoundedRectangle(cornerRadius: 220, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.16 : 0.34))
                .frame(width: 300, height: 440)
                .blur(radius: 52)
                .offset(x: 160, y: 210)
        }
        .ignoresSafeArea()
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.03, green: 0.09, blue: 0.18),
                Color(red: 0.07, green: 0.17, blue: 0.27),
                Color(red: 0.02, green: 0.22, blue: 0.28)
            ]
        }

        return [
            Color(red: 0.88, green: 0.95, blue: 0.99),
            Color(red: 0.84, green: 0.95, blue: 0.94),
            Color(red: 0.93, green: 0.97, blue: 1.0)
        ]
    }
}
