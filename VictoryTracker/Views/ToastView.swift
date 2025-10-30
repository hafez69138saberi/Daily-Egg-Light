import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.white)
            Text(message)
                .foregroundColor(.white)
                .font(.subheadline).bold()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.success)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview {
    ZStack {
        Color(.systemBackground)
        ToastView(message: "Victory saved")
            .padding(.top, 40)
            .frame(maxHeight: .infinity, alignment: .top)
    }
}


