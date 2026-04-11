//
//  TimerAnimationStyles.swift
//  FocusTimer
//
//  F48: Multiple timer animation styles - circular, pixel, minimal, zen garden
import Foundation
import Combine
import SwiftUI
//

import SwiftUI

// MARK: - Timer Animation Style

enum TimerAnimationStyle: String, Codable, CaseIterable {
    case circular = "circular"
    case pixel = "pixel"
    case minimal = "minimal"
    case zenGarden = "zen_garden"
    
    var displayName: String {
        switch self {
        case .circular: return "Circular"
        case .pixel: return "Pixel Art"
        case .minimal: return "Minimal"
        case .zenGarden: return "Zen Garden"
        }
    }
    
    var icon: String {
        switch self {
        case .circular: return "circle.circle"
        case .pixel: return "square.grid.3x3"
        case .minimal: return "number"
        case .zenGarden: return "leaf"
        }
    }
    
    var description: String {
        switch self {
        case .circular: return "Classic circular progress"
        case .pixel: return "Retro pixel countdown"
        case .minimal: return "Clean numeric display"
        case .zenGarden: return "Peaceful sand garden"
        }
    }
}

// MARK: - Timer Style Manager

class TimerStyleManager: ObservableObject {
    static let shared = TimerStyleManager()
    
    @Published var currentStyle: TimerAnimationStyle = .circular
    
    private init() {
        load()
    }
    
    func setStyle(_ style: TimerAnimationStyle) {
        currentStyle = style
        save()
    }
    
    private func save() {
        UserDefaults.standard.set(currentStyle.rawValue, forKey: "timer_animation_style")
    }
    
    func load() {
        if let saved = UserDefaults.standard.string(forKey: "timer_animation_style"),
           let style = TimerAnimationStyle(rawValue: saved) {
            currentStyle = style
        }
    }
}

// MARK: - Animated Timer Views

struct AnimatedTimerView<Content: View>: View {
    let progress: Double
    let timeRemaining: Int
    let isWorkPhase: Bool
    let style: TimerAnimationStyle
    let content: () -> Content
    
    var body: some View {
        switch style {
        case .circular:
            CircularTimerView(progress: progress, timeRemaining: timeRemaining, isWorkPhase: isWorkPhase)
        case .pixel:
            PixelTimerView(progress: progress, timeRemaining: timeRemaining, isWorkPhase: isWorkPhase)
        case .minimal:
            MinimalTimerView(progress: progress, timeRemaining: timeRemaining, isWorkPhase: isWorkPhase)
        case .zenGarden:
            ZenGardenTimerView(progress: progress, timeRemaining: timeRemaining, isWorkPhase: isWorkPhase)
        }
    }
}

// MARK: - Circular Timer (Default)

struct CircularTimerView: View {
    let progress: Double
    let timeRemaining: Int
    let isWorkPhase: Bool
    
    private var color: Color {
        isWorkPhase ? Color(hex: "FF6B6B") : Color(hex: "4ECB71")
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color(hex: "3A3A3C"), lineWidth: 12)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            
            // Time display
            VStack(spacing: 4) {
                Text(formattedTime)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text(isWorkPhase ? "FOCUS" : "BREAK")
                    .font(.caption.bold())
                    .foregroundColor(color)
            }
        }
    }
    
    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Pixel Timer View

struct PixelTimerView: View {
    let progress: Double
    let timeRemaining: Int
    let isWorkPhase: Bool
    
    private let gridSize = 5
    private let spacing: CGFloat = 4
    
    private var color: Color {
        isWorkPhase ? Color(hex: "FF6B6B") : Color(hex: "4ECB71")
    }
    
    private var filledBlocks: Int {
        Int(progress * Double(gridSize * gridSize))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Pixel grid
            VStack(spacing: spacing) {
                ForEach(0..<gridSize, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<gridSize, id: \.self) { col in
                            let index = row * gridSize + col
                            RoundedRectangle(cornerRadius: 2)
                                .fill(index < filledBlocks ? color : Color(hex: "3A3A3C"))
                                .frame(width: 24, height: 24)
                        }
                    }
                }
            }
            .padding(24)
            .background(Color(hex: "1C1C1E"))
            .cornerRadius(16)
            
            // Time display
            Text(formattedTime)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Text(isWorkPhase ? "FOCUS" : "BREAK")
                .font(.caption.bold())
                .foregroundColor(color)
        }
    }
    
    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Minimal Timer View

struct MinimalTimerView: View {
    let progress: Double
    let timeRemaining: Int
    let isWorkPhase: Bool
    
    @State private var opacity: Double = 1.0
    
    private var color: Color {
        isWorkPhase ? Color(hex: "FF6B6B") : Color(hex: "4ECB71")
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(formattedTime)
                .font(.system(size: 72, weight: .thin, design: .monospaced))
                .foregroundColor(.white.opacity(opacity))
                .animation(.easeInOut(duration: 1), value: opacity)
            
            Text(isWorkPhase ? "FOCUS" : "BREAK")
                .font(.caption.bold())
                .foregroundColor(color)
                .tracking(4)
            
            // Subtle progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(hex: "3A3A3C"))
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                        .animation(.linear(duration: 1), value: progress)
                }
            }
            .frame(height: 2)
            .frame(maxWidth: 200)
            .cornerRadius(1)
        }
        .onAppear {
            // Subtle pulse effect
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                opacity = 0.7
            }
        }
    }
    
    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Zen Garden Timer View

struct ZenGardenTimerView: View {
    let progress: Double
    let timeRemaining: Int
    let isWorkPhase: Bool
    
    @State private var sandOffset: CGFloat = 0
    
    private var color: Color {
        isWorkPhase ? Color(hex: "C4A77D") : Color(hex: "4ECB71")
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Zen circle (enso-like)
            ZStack {
                // Sand background with pattern
                Circle()
                    .stroke(Color(hex: "3A3A3C"), lineWidth: 2)
                    .frame(width: 200, height: 200)
                
                // Inner filling circle (like sand being poured)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                
                // Center time
                VStack(spacing: 4) {
                    Text(formattedTime)
                        .font(.system(size: 32, weight: .light, design: .monospaced))
                        .foregroundColor(.white)
                    
                    if isWorkPhase {
                        Image(systemName: "leaf.fill")
                            .font(.caption)
                            .foregroundColor(Color(hex: "4ECB71").opacity(0.7))
                    }
                }
            }
            .padding(20)
            .background(
                RadialGradient(
                    colors: [Color(hex: "2C2C2E"), Color(hex: "1C1C1E")],
                    center: .center,
                    startRadius: 50,
                    endRadius: 150
                )
            )
            .cornerRadius(200)
            
            // Phase label
            Text(isWorkPhase ? "Breathe and focus" : "Rest and restore")
                .font(.caption)
                .foregroundColor(Color(hex: "8E8E93"))
                .italic()
        }
    }
    
    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Timer Style Selector

struct TimerStyleSelectorView: View {
    @StateObject private var styleManager = TimerStyleManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(TimerAnimationStyle.allCases, id: \.self) { style in
                            TimerStyleCard(
                                style: style,
                                isSelected: styleManager.currentStyle == style,
                                onSelect: {
                                    styleManager.setStyle(style)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Timer Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "FF6B6B"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct TimerStyleCard: View {
    let style: TimerAnimationStyle
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Style preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "2C2C2E"))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: style.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? Color(hex: "FF6B6B") : Color(hex: "8E8E93"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(style.description)
                        .font(.caption)
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "FF6B6B"))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "2C2C2E"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color(hex: "FF6B6B") : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}
