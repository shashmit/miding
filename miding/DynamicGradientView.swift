
import SwiftUI

struct DynamicGradientView: View {
    @ObservedObject var viewModel: StatisticsViewModel
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Base background
                #if os(macOS)
                Color(nsColor: .windowBackgroundColor)
                #else
                Color(uiColor: .systemBackground)
                #endif
                
                // Animated Gradient
                // We shift the start/end points based on bias
                // Bias -1 (Tasks) -> Left side dominant (Blue/Cyan)
                // Bias 1 (Tickets) -> Right side dominant (Purple/Pink)
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.3),
                        Color.purple.opacity(0.3)
                    ]),
                    startPoint: UnitPoint(x: 0.0 + (viewModel.gradientBias * 0.5), y: 0),
                    endPoint: UnitPoint(x: 1.0 + (viewModel.gradientBias * 0.5), y: 1)
                )
                .animation(.easeInOut(duration: 1.0), value: viewModel.gradientBias)
                .blur(radius: 50)
                
                // Add a "spotlight" effect
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.1),
                        Color.clear
                    ]),
                    center: UnitPoint(x: 0.5 - (viewModel.gradientBias * 0.3), y: 0.5),
                    startRadius: 0,
                    endRadius: 400
                )
            }
        }
        .ignoresSafeArea()
    }
}
