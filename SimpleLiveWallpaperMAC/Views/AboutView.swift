//  AboutView.swift
//  SimpleLiveWallpaperMAC
//
//  Created by Вадим Вехов on 13.01.2026.
//
import SwiftUI

struct AboutView: View {
    var body: some View {
        TitleView()
        VStack() {
            
            Text("Приложение разработано для бесплатной установки живых обоев на рабочий стол MacBook")
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// Предпросмотр для SwiftUI Canvas
struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
