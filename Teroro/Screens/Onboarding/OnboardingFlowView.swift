import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var appState: AppState

    @ObservedObject var viewModel: OnboardingFlowVM
    @State private var iconRotation: Double = 0
    @State private var frontIconName: String = ""
    @State private var backIconName: String = ""

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                OnboardingPageView(
                    step: viewModel.currentStepData,
                    iconRotation: iconRotation,
                    frontIconName: frontIconName,
                    backIconName: backIconName
                )
                .padding(.horizontal, 24)

                bottomBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 35)
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            frontIconName = viewModel.currentStepData.img
            backIconName = viewModel.currentStepData.img
            viewModel.onStepChanged(to: viewModel.currentStep)
        }
        .onChange(of: viewModel.currentStep) { newValue in
            let newName = viewModel.steps[newValue].img
            backIconName = newName
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                iconRotation += 180
            }
            // Keep the "front" value in sync after the flip completes.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                frontIconName = newName
            }
            viewModel.onStepChanged(to: newValue)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 14) {
            OnboardingPageIndicator(count: viewModel.steps.count, index: viewModel.currentStep)

            PrimaryButton(
                title: viewModel.isLastStep ? "Продовжити" : "Далі",
                style: .primaryWhiteText,
                frameHeight: 54
            ) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.handlePrimaryButtonTap(appState: appState)
                }
            }
            
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.secondarySystemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct OnboardingPageView: View {
    let step: OnboardingStep
    let iconRotation: Double
    let frontIconName: String
    let backIconName: String

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.08))
                    .frame(width: 220, height: 220)
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 150, height: 150)

                OnboardingFlippingIcon(
                    rotation: iconRotation,
                    frontName: frontIconName,
                    backName: backIconName
                )
            }
            .padding(.top, 18)

            VStack(spacing: 10) {
                SlidingSwapText(
                    text: step.title,
                    font: .system(size: 28, weight: .bold),
                    color: .primary,
                    lineSpacing: 0
                )

                SlidingSwapText(
                    text: step.subtitle,
                    font: .system(size: 16, weight: .medium),
                    color: .secondary,
                    lineSpacing: 2
                )
            }

            Spacer(minLength: 0)
        }
    }
}

private struct OnboardingFlippingIcon: View {
    let rotation: Double
    let frontName: String
    let backName: String

    var body: some View {
        let angle = rotation.truncatingRemainder(dividingBy: 360)
        let showingFront = (angle < 90) || (angle > 270)

        return ZStack {
            OnboardingIcon(name: frontName)
                .opacity(showingFront ? 1 : 0)
                .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0), perspective: 0.8)
                .scaleEffect(showingFront ? 1 : 0.96)

            OnboardingIcon(name: backName)
                .opacity(showingFront ? 0 : 1)
                .rotation3DEffect(.degrees(rotation + 180), axis: (x: 0, y: 1, z: 0), perspective: 0.8)
                .scaleEffect(showingFront ? 0.96 : 1)
        }
        .frame(width: 74, height: 74)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct OnboardingIcon: View {
    let name: String

    var body: some View {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        Group {
            if trimmed.isEmpty {
                Color.clear
            } else if UIImage(named: trimmed) != nil {
                Image(trimmed)
                    .resizable()
                    .scaledToFit()
                    .padding(14)
            } else {
                Image(systemName: trimmed)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.blue)
            }
        }
        .frame(width: 74, height: 74)
    }
}

private struct SlidingSwapText: View {
    let text: String
    let font: Font
    let color: Color
    let lineSpacing: CGFloat

    @State private var current: String = ""
    @State private var previous: String? = nil
    @State private var showNew: Bool = true

    var body: some View {
        ZStack {
            if let prev = previous {
                Text(prev)
                    .font(font)
                    .foregroundStyle(color)
                    .multilineTextAlignment(.center)
                    .lineSpacing(lineSpacing)
                    .offset(x: showNew ? -36 : 0)
                    .opacity(showNew ? 0 : 1)
            }

            Text(current)
                .font(font)
                .foregroundStyle(color)
                .multilineTextAlignment(.center)
                .lineSpacing(lineSpacing)
                .offset(x: showNew ? 0 : 36)
                .opacity(showNew ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            current = text
            previous = nil
            showNew = true
        }
        .onChange(of: text) { newValue in
            guard newValue != current else { return }
            previous = current
            current = newValue
            showNew = false

            withAnimation(.easeInOut(duration: 0.38)) {
                showNew = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                previous = nil
            }
        }
    }
}

private struct OnboardingPageIndicator: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { i in
                Capsule(style: .continuous)
                    .fill(i == index ? Color.primary.opacity(0.9) : Color.secondary.opacity(0.35))
                    .frame(width: i == index ? 22 : 6, height: 6)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: index)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        OnboardingFlowView(viewModel: OnboardingFlowVM())
            .environmentObject(AppState())
    }
}
