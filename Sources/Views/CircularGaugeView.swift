import SwiftUI

struct CircularGaugeView: View {
    let utilization: Double
    let label: String
    let resetTime: String?
    var size: CGFloat = 110

    private var progress: Double {
        min(max(utilization / 100.0, 0), 1)
    }

    private var gaugeColor: Color {
        switch utilization {
        case ..<50: return .green
        case ..<80: return .yellow
        default: return .red
        }
    }

    private var lineWidth: CGFloat {
        size >= 100 ? 8 : 6
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(gaugeColor.opacity(0.2), lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(gaugeColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)

                VStack(spacing: 1) {
                    Text("\(Int(utilization))%")
                        .font(.system(size: size >= 100 ? 20 : 14, weight: .bold, design: .rounded))
                    Text(label)
                        .font(.system(size: size >= 100 ? 10 : 8))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: size, height: size)

            if let resetTime {
                Text(resetTime)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
