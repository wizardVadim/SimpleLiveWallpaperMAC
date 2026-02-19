//  AboutView.swift
//  SimpleLiveWallpaperMAC
//
//  Created by Вадим Вехов on 13.01.2026.
//
import SwiftUI

struct AboutView: View {
    
    @EnvironmentObject var wallpaperManager: WallpaperManager
    
    var body: some View {
        VStack() {
            
            Text("about_text")
                .frame(maxHeight: .infinity, )
            
            HStack() {
                Button("clean_settings") {
                    wallpaperManager.reboot()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(alignment: .bottom)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

// Предпросмотр для SwiftUI Canvas
struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
