//
//  TitleView.swift
//  SimpleLiveWallpaperMAC
//
//  Created by Вадим Вехов on 13.01.2026.
//
import SwiftUI

struct TitleView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("SL Wallpapers")
                .font(.largeTitle)
                .padding(30)
            Divider()
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
