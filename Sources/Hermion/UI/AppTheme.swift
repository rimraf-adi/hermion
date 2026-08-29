import SwiftUI

public enum AppTheme: String, CaseIterable, Identifiable {
    case nebulaPurple = "Nebula Purple"
    case cyberCyan = "Cyber Cyan"
    case sunsetCoral = "Sunset Coral"
    case emeraldMint = "Emerald Mint"
    case obsidianSlate = "Obsidian Slate"
    
    public var id: String { self.rawValue }
    
    public var primaryColor: Color {
        switch self {
        case .nebulaPurple: return Color(red: 0.55, green: 0.36, blue: 0.96) // #8B5CF6
        case .cyberCyan: return Color(red: 0.02, green: 0.71, blue: 0.83)   // #06B6D4
        case .sunsetCoral: return Color(red: 0.96, green: 0.40, blue: 0.35) // #F56565
        case .emeraldMint: return Color(red: 0.06, green: 0.73, blue: 0.51) // #10B981
        case .obsidianSlate: return Color(red: 0.88, green: 0.91, blue: 0.94) // #E2E8F0
        }
    }
    
    public var secondaryColor: Color {
        switch self {
        case .nebulaPurple: return Color(red: 0.39, green: 0.40, blue: 0.95) // #6366F1
        case .cyberCyan: return Color(red: 0.08, green: 0.72, blue: 0.65)   // #14B8A6
        case .sunsetCoral: return Color(red: 0.96, green: 0.25, blue: 0.37) // #F43F5E
        case .emeraldMint: return Color(red: 0.02, green: 0.59, blue: 0.41) // #059669
        case .obsidianSlate: return Color(red: 0.44, green: 0.47, blue: 0.53) // #71717A
        }
    }
    
    public var gradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor, secondaryColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    public var glowColor: Color {
        primaryColor.opacity(0.5)
    }
}

public class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()
    
    @Published public var currentTheme: AppTheme = .nebulaPurple
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: "Hermion_AppTheme"),
           let theme = AppTheme(rawValue: saved) {
            self.currentTheme = theme
        }
    }
    
    public func setTheme(_ theme: AppTheme) {
        self.currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "Hermion_AppTheme")
    }
}
