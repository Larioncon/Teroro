import SwiftUI
import RevenueCat

struct OnboardingPaywallView: View {
    var onboardingRouter: AppRouter? = nil
    @EnvironmentObject private var appState: AppState
    @Environment(\.openURL) private var openURL
    @StateObject private var subscriptionService = SubscriptionService.shared

    var body: some View {
        ZStack {
            // Liquid Shader/Gradient Background
            LiquidShaderView()
            
            // Bioluminescent Cellular Organism
            CellularOrganismView()

            VStack(spacing: 20) {
                // Top header with close/skip button
                HStack {
                    Button {
                        dismissPaywall()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer()

                // Content area
                VStack(spacing: 10) {
                    Text("Manage Terms & Stay Focused")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Unlock Timexo Premium to keep terms, reminders, and focus tools fully available.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
//                        .padding(.horizontal, 24)
                }
                .padding(.horizontal, 24)
                // Dynamic price text
                let price = subscriptionService.localizedPrice(for: AppConstants.weeklyTrialProductID)
                Text("3 Days Free, then \(price)/week")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))

                // CTA & Price Area
                VStack(spacing: 12) {
                    Button {
                        Task {
                            let didPurchase = await subscriptionService.purchase(productID: AppConstants.weeklyTrialProductID)
                            if didPurchase {
                                dismissPaywall()
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if subscriptionService.isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            }
                            
                            Text(subscriptionService.isPurchasing ? "Processing..." : "Get Started")
                                .font(.headline)
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(subscriptionService.isPurchasing ? Color.white.opacity(0.5) : Color.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(subscriptionService.isPurchasing)
                    .padding(.horizontal, 20)

                   
                }
                .padding(.top, 10)

                // Footer links
                footerLinks
                 .padding(.bottom, 30)
                   
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.all, edges: .bottom)
        .task {
            await subscriptionService.bootstrap()
        }
        .alert("Error", isPresented: Binding(get: {
            subscriptionService.errorMessage != nil
        }, set: { newValue in
            if !newValue {
                subscriptionService.clearError()
            }
        }), actions: {
            Button("OK") {
                subscriptionService.clearError()
            }
        }, message: {
            Text(subscriptionService.errorMessage ?? "")
        })
    }

    private var footerLinks: some View {
        HStack(spacing: 12) {
            Button("Restore") {
                Task {
                    let didRestore = await subscriptionService.restore()
                    if didRestore {
                        dismissPaywall()
                    }
                }
            }

            Text("•")
                .foregroundStyle(.white.opacity(0.3))

            Button("Terms and conditions") {
                open(AppConstants.termsOfUseLink)
            }

            Text("•")
                .foregroundStyle(.white.opacity(0.3))

            Button("Privacy policy") {
                open(AppConstants.privacyPolicyLink)
            }
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.white.opacity(0.5))
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .disabled(subscriptionService.isPurchasing)
    }

    private func open(_ string: String) {
        guard let url = URL(string: string) else { return }
        openURL(url)
    }

    private func dismissPaywall() {
        if let onboardingRouter {
            onboardingRouter.popToRoot()
        } else {
            appState.isShowPwTrial = false
        }
    }
}

struct LiquidShaderView: View {
    let startDate = Date()
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            if #available(iOS 17.0, *) {
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSince(startDate)
                    Color.black
                        .colorEffect(
                            ShaderLibrary.liquidShader(
                                .float(time),
                                .float2(size.width, size.height)
                            )
                        )
                }
            } else {
                // iOS 16 and below fallback using animating gradients with SwiftUI
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSince1970
                    let xOffset1 = sin(time * 0.3) * (size.width * 0.3)
                    let yOffset1 = cos(time * 0.4) * (size.height * 0.2)
                    let xOffset2 = cos(time * 0.5) * (size.width * 0.3)
                    let yOffset2 = sin(time * 0.3) * (size.height * 0.2)
                    
                    ZStack {
                        Color(red: 0.05, green: 0.02, blue: 0.12)
                        
                        RadialGradient(
                            colors: [Color(red: 0.35, green: 0.25, blue: 0.9).opacity(0.85), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size.width * 0.8
                        )
                        .frame(width: size.width * 1.5, height: size.width * 1.5)
                        .offset(x: xOffset1, y: yOffset1 - 100)
                        .blur(radius: 60)
                        
                        RadialGradient(
                            colors: [Color(red: 0.09, green: 0.55, blue: 0.95).opacity(0.85), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size.width * 0.8
                        )
                        .frame(width: size.width * 1.5, height: size.width * 1.5)
                        .offset(x: xOffset2 + 100, y: yOffset2 + 100)
                        .blur(radius: 60)
                    }
                    .drawingGroup()
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct CellularOrganismView: View {
    let startDate = Date()
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSince(startDate)
            
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height * 0.38)
                
                // Draw 24 overlapping organic rectangular cells
                for i in 0..<24 {
                    let seed = Double(i)
                    
                    // Distinct speeds and phases for organic, lifelike movement
                    let driftX = sin(time * 0.4 + seed * 1.7) * 25
                    let driftY = cos(time * 0.3 + seed * 2.1) * 30
                    let pulseScale = 0.85 + sin(time * 0.9 + seed * 0.8) * 0.15
                    let rotation = time * 8.0 + seed * 45.0 + sin(time * 0.6 + seed) * 15.0
                    
                    // Dimensions matching the sketch
                    let rectWidth: CGFloat = 30.0 + CGFloat(sin(seed * 9.0) * 12.0)
                    let rectHeight: CGFloat = 40.0 + CGFloat(cos(seed * 5.0) * 15.0)
                    
                    // Cellular group arrangement (cluster like the sketch)
                    // Two main sub-clusters that slightly breathe/drift apart (split cluster look)
                    let subClusterOffset: CGFloat = i % 2 == 0 ? -30 : 30
                    let xPos = center.x + subClusterOffset + CGFloat(sin(seed * 12.0) * 40.0) + CGFloat(driftX)
                    let yPos = center.y + CGFloat(cos(seed * 7.0) * 60.0) + CGFloat(driftY)
                    
                    context.drawLayer { ctx in
                        ctx.translateBy(x: xPos, y: yPos)
                        ctx.rotate(by: Angle(degrees: rotation))
                        ctx.scaleBy(x: CGFloat(pulseScale), y: CGFloat(pulseScale))
                        
                        let rect = CGRect(
                            x: -rectWidth / 2,
                            y: -rectHeight / 2,
                            width: rectWidth,
                            height: rectHeight
                        )
                        
                        // Green marker glow color
                        let cellOpacity = 0.55 + sin(time * 1.1 + seed) * 0.25
                        let greenColor = Color(
                            red: 0.0,
                            green: 0.8 + cos(seed) * 0.15,
                            blue: 0.35 + sin(seed) * 0.15,
                            opacity: cellOpacity
                        )
                        
                        // Mix hollow organic outlines and solid square floaters
                        if i % 5 == 0 {
                            // Solid floater cell
                            let size: CGFloat = 12 + CGFloat(cos(seed) * 4)
                            let floaterRect = CGRect(x: -size/2, y: -size/2, width: size, height: size)
                            ctx.fill(Path(floaterRect), with: .color(greenColor))
                        } else {
                            // Hollow rectangle outline matching the overlapping sketch structure
                            ctx.stroke(
                                Path(rect),
                                with: .color(greenColor),
                                style: StrokeStyle(lineWidth: 2.2, lineJoin: .round)
                            )
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}
