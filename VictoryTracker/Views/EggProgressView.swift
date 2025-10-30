import SwiftUI

struct EggProgressView: View {
    let progress: Double

    private var eggColor: Color {
        let clamped = max(0.0, min(1.0, progress))
        return Color(hue: 0.08, saturation: 0.7 * clamped + 0.3, brightness: 0.75)
    }

    private var glowRadius: CGFloat { CGFloat(8 + 22 * progress) }
    private var glowOpacity: Double { 0.25 + 0.45 * progress }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Achievement Egg")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.subheadline).bold()
                    .foregroundColor(Theme.textSecondary)
            }

            ZStack {
                Ellipse()
                    .fill(eggColor)
                    .shadow(color: eggColor.opacity(glowOpacity), radius: glowRadius, x: 0, y: 0)
                    .frame(width: 200, height: 260)
                    .scaleEffect(x: 0.9, y: 1.0)
            }
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.cardBackground)
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.cardBackground)
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .padding(.vertical, 4)
    }
}

private struct EggShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let cx = rect.midX
        let cy = rect.midY
        let top = CGPoint(x: cx, y: rect.minY + h * 0.08)
        let right = CGPoint(x: rect.maxX - w * 0.18, y: cy + h * 0.10)
        let bottom = CGPoint(x: cx, y: rect.maxY - h * 0.04)
        let left = CGPoint(x: rect.minX + w * 0.18, y: cy + h * 0.10)

        var p = Path()
        p.move(to: top)

        p.addCurve(
            to: right,
            control1: CGPoint(x: cx + w * 0.22, y: rect.minY + h * 0.02),
            control2: CGPoint(x: rect.maxX - w * 0.06, y: cy - h * 0.02)
        )
        p.addCurve(
            to: bottom,
            control1: CGPoint(x: rect.maxX - w * 0.02, y: cy + h * 0.40),
            control2: CGPoint(x: cx + w * 0.22, y: rect.maxY)
        )
        p.addCurve(
            to: left,
            control1: CGPoint(x: cx - w * 0.22, y: rect.maxY),
            control2: CGPoint(x: rect.minX + w * 0.02, y: cy + h * 0.40)
        )
        p.addCurve(
            to: top,
            control1: CGPoint(x: rect.minX + w * 0.06, y: cy - h * 0.02),
            control2: CGPoint(x: cx - w * 0.22, y: rect.minY + h * 0.02)
        )
        p.closeSubpath()
        return p
    }
}

#Preview {
    ZStack {
        Theme.primaryBackground.ignoresSafeArea()
        EggProgressView(progress: 0.2)
            .padding()
    }
}


