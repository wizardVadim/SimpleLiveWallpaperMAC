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
    @Binding var selection: AppPage?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Заголовок + toggle
            HStack {
                Text("Живые обои")
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
                Text("Состояние")
                Spacer()
                Text(wallpaperManager.isPlaying ? "Играет" : "Остановлено")
                    .foregroundColor(wallpaperManager.isPlaying ? .green : .red)
            }
            .font(.subheadline)

            Divider()

            // Меню
            List {
                Section("Основные") {
                    ForEach(AppPage.allCases) { page in
                        HStack {
                            Image(systemName: icon(for: page))
                                .foregroundColor(selection == page ? STYLE_COLOR_L : STYLE_COLOR_D)
                            Text(page.rawValue)
                                .foregroundColor(selection == page ? STYLE_COLOR_L : .primary)
                            Spacer()
                        }
                        .padding(5)
                        .background(selection == page ? STYLE_COLOR_L.opacity(0.3) : Color.clear)
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
    case home = "Главная"
    case wallpapers = "Мои обои"
    case queue = "Очередь"
    case about = "О приложении"
    

    var id: String { rawValue }
}

// Предпросмотр для SwiftUI Canvas
struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView(selection: .constant(.home))
            .frame(maxWidth: 250)
            .environmentObject(WallpaperManager())
    }
}
