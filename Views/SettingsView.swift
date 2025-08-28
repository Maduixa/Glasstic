import SwiftUI

struct SettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: themeManager.currentTheme.primaryGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        VStack(spacing: 10) {
                            Text("Settings")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Customize your fasting experience")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        themeSection
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(themeManager.currentTheme.mode)
        }
    }
    
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Themes")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(AppTheme.allThemes) { theme in
                    themeCard(theme: theme)
                }
            }
            
            Button("Close") {
                dismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(15)
            .padding(.top, 10)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    private func themeCard(theme: AppTheme) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                themeManager.setTheme(theme)
            }
        }) {
            VStack(spacing: 12) {
                // Theme preview
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: theme.primaryGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: theme.progressGradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                
                Text(theme.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                themeManager.currentTheme.id == theme.id ? 
                                    Color.yellow.opacity(0.8) : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .scaleEffect(themeManager.currentTheme.id == theme.id ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: themeManager.currentTheme.id == theme.id)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}