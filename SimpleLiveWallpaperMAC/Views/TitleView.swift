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
                .frame(alignment: .center)
            
            HStack {
                
            }
            .frame(maxWidth: .infinity)
            Divider()
            
        }
        .frame(alignment: .top)
    }
}
