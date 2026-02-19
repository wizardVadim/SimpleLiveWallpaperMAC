//
//  SidebarView.swift
//  SimpleLiveWallpaperMAC
//
//  Created by Вадим Вехов on 13.01.2026.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct SidebarView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @Environment(\.colorScheme) var colorScheme
    @Binding var selection: AppPage?

    var body: some View {
        
        let colorToFont = (colorScheme == .dark) ? STYLE_COLOR_L : Color.primary
        let colorToBackgroundBorder = (colorScheme == .dark) ? STYLE_COLOR_L.opacity(0.3) : Color.gray.opacity(0.1)
        let colorToSelectedImage = (colorScheme == .dark) ? STYLE_COLOR_L : Color.primary
        let colorToImage = (colorScheme == .dark) ? STYLE_COLOR_D : Color.primary
        
        VStack(alignment: .leading, spacing: 12) {

            // Заголовок + toggle
            HStack {
                Text("live_wallpapers")
                    .font(.headline)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { wallpaperManager.isPlaying },
                    set: { isOn in
                        isOn ? wallpaperManager.start() : wallpaperManager.stop()
                    }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(STYLE_COLOR_D)
            }

            // Статус
            HStack {
                Text("state")
                Spacer()
                Text(wallpaperManager.isPlaying ? "playing" : "stopped")
                    .foregroundColor(wallpaperManager.isPlaying ? .green : .red)
            }
            .font(.subheadline)

            Divider()

            // Меню
            List {
                Section("main") {
                    ForEach(AppPage.allCases) { page in
                        HStack {
                            Image(systemName: icon(for: page))
                                .foregroundColor(selection == page ? colorToSelectedImage : colorToImage)
                            Text(page.localizedName)
                                .foregroundColor(selection == page ? colorToFont : .primary)
                            Spacer()
                        }
                        .padding(5)
                        .background(selection == page ? colorToBackgroundBorder : Color.clear)
                        .cornerRadius(6)
                        .onTapGesture {
                            selection = page
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        }
        .padding()
        .frame(width: 200)
        
    }

    private func icon(for page: AppPage) -> String {
        switch page {
        case .home: return "house"
        case .wallpapers: return "photo.on.rectangle"
        case .queue: return "list.bullet"
        case .about: return "info.circle"
        }
    }
}

enum AppPage: String, CaseIterable, Identifiable {
    case home = "home"
    case wallpapers = "wallpapers"
    case queue = "queue"
    case about = "about"
    

    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .home:
            return NSLocalizedString("home", comment: "Home page title")
        case .wallpapers:
            return NSLocalizedString("wallpapers", comment: "Wallpapers page title")
        case .queue:
            return NSLocalizedString("queue", comment: "Queue page title")
        case .about:
            return NSLocalizedString("about", comment: "About page title")
        }
    }
}

// Предпросмотр для SwiftUI Canvas
struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView(selection: .constant(.home))
            .frame(maxWidth: 250)
            .environmentObject(WallpaperManager())
    }
}
