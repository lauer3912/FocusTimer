//
//  FocusSounds.swift
//  FocusTimer
//

import Foundation
import Combine
import AVFoundation
import AudioToolbox

// MARK: - Sound Type

enum FocusSoundType: String, CaseIterable, Codable, Identifiable {
    case none = "none"
    case rain = "rain"
    case forest = "forest"
    case ocean = "ocean"
    case coffeeShop = "coffee_shop"
    case fireplace = "fireplace"
    case lofi = "lofi"
    case whiteNoise = "white_noise"
    case brownNoise = "brown_noise"
    case pinkNoise = "pink_noise"
    case wind = "wind"
    case birds = "birds"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .rain: return "Rain"
        case .forest: return "Forest"
        case .ocean: return "Ocean Waves"
        case .coffeeShop: return "Coffee Shop"
        case .fireplace: return "Fireplace"
        case .lofi: return "Lo-Fi Beats"
        case .whiteNoise: return "White Noise"
        case .brownNoise: return "Brown Noise"
        case .pinkNoise: return "Pink Noise"
        case .wind: return "Wind"
        case .birds: return "Birds Chirping"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "speaker.slash.fill"
        case .rain: return "cloud.rain.fill"
        case .forest: return "leaf.fill"
        case .ocean: return "water.waves"
        case .coffeeShop: return "cup.and.saucer.fill"
        case .fireplace: return "flame.fill"
        case .lofi: return "headphones"
        case .whiteNoise: return "waveform"
        case .brownNoise: return "waveform.path"
        case .pinkNoise: return "waveform.circle"
        case .wind: return "wind"
        case .birds: return "bird.fill"
        }
    }
    
    var frequency: Float {
        switch self {
        case .whiteNoise: return 0
        case .brownNoise: return 1
        case .pinkNoise: return 2
        default: return -1
        }
    }
}

// MARK: - Sound Manager

class FocusSoundManager: ObservableObject {
    static let shared = FocusSoundManager()
    
    @Published var currentSound: FocusSoundType = .none
    @Published var volume: Float = 0.5
    @Published var isPlaying: Bool = false
    
    private var audioPlayer: AVAudioPlayer?
    private var noiseGenerator: AVAudioEngine?
    private var noiseNode: AVAudioSourceNode?
    
    func play(sound: FocusSoundType) {
        stop()
        
        currentSound = sound
        
        if sound == .none {
            return
        }
        
        // For noise types, generate them programmatically
        if sound.frequency >= 0 {
            generateNoise(type: sound)
        } else {
            // For ambient sounds, we would load audio files
            // Since we don't have actual audio files, we'll simulate with system sounds
            playSystemSound()
        }
        
        isPlaying = true
    }
    
    func stop() {
        isPlaying = false
        audioPlayer?.stop()
        audioPlayer = nil
        noiseGenerator?.stop()
        noiseGenerator = nil
        noiseNode = nil
    }
    
    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        audioPlayer?.volume = volume
    }
    
    private func playSystemSound() {
        // Play notification sound for non-noise ambient sounds
        // In production, you would load actual audio files from bundle
        // For now, use system sound as placeholder
        AudioServicesPlaySystemSound(1007) // Default notification sound
    }
    
    private func generateNoise(type: FocusSoundType) {
        noiseGenerator?.stop()
        noiseGenerator = nil
        noiseNode = nil
        
        let engine = AVAudioEngine()
        let sampleRate: Double = 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        // Noise state variables
        var b0: Float = 0, b1: Float = 0, b2: Float = 0, b3: Float = 0, b4: Float = 0, b5: Float = 0, b6: Float = 0
        var pinkState: [Float] = [0, 0, 0, 0, 0, 0, 0]
        
        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let buffer = ablPointer[0]
            let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)
            
            for frame in 0..<Int(frameCount) {
                var sample: Float = 0
                
                switch type {
                case .whiteNoise:
                    // Pure random white noise
                    sample = Float.random(in: -1...1) * self.volume
                    
                case .brownNoise:
                    // Brown noise (random walk, deeper than pink)
                    let white = Float.random(in: -1...1)
                    b0 = 0.99886 * b0 + white * 0.0555179
                    b1 = 0.99332 * b1 + white * 0.0750759
                    b2 = 0.96900 * b2 + white * 0.1538520
                    b3 = 0.86650 * b3 + white * 0.3104856
                    b4 = 0.55000 * b4 + white * 0.5329522
                    b5 = -0.7616 * b5 - white * 0.0168980
                    sample = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * 0.11
                    b6 = white * 0.115926
                    sample *= self.volume
                    
                case .pinkNoise:
                    // Pink noise (1/f noise, between white and brown)
                    let white = Float.random(in: -1...1)
                    pinkState[0] = 0.99886 * pinkState[0] + white * 0.0555179
                    pinkState[1] = 0.99332 * pinkState[1] + white * 0.0750759
                    pinkState[2] = 0.96900 * pinkState[2] + white * 0.1538520
                    pinkState[3] = 0.86650 * pinkState[3] + white * 0.3104856
                    pinkState[4] = 0.55000 * pinkState[4] + white * 0.5329522
                    pinkState[5] = -0.7616 * pinkState[5] - white * 0.0168980
                    let pink = (pinkState[0] + pinkState[1] + pinkState[2] + pinkState[3] + pinkState[4] + pinkState[5] + pinkState[6] + white * 0.5362) * 0.11
                    pinkState[6] = white * 0.115926
                    sample = pink * self.volume
                    
                default:
                    sample = 0
                }
                
                ptr[frame] = sample
            }
            
            return noErr
        }
        
        noiseGenerator = engine
        noiseNode = node
        
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        
        do {
            try engine.start()
        } catch {
            print("Failed to start noise generator: \(error)")
        }
    }
    
    func save() {
        UserDefaults.standard.set(currentSound.rawValue, forKey: "focus_sound")
        UserDefaults.standard.set(volume, forKey: "focus_sound_volume")
    }
    
    func load() {
        if let raw = UserDefaults.standard.string(forKey: "focus_sound"),
           let sound = FocusSoundType(rawValue: raw) {
            currentSound = sound
        }
        volume = UserDefaults.standard.float(forKey: "focus_sound_volume")
        if volume == 0 { volume = 0.5 }
    }
}
