//
//  Wallpaper.swift
//  SimpleLiveWallpaperMAC
//
//  Created by Вадим Вехов on 13.12.2025.
//

import Foundation

struct Wallpaper: Identifiable, Codable {
    let id: UUID
    var url: URL
    var title: String
    var fileName: String
    var duration: TimeInterval?
    var fileSize: Int64?
    var resolution: (width: Int, height: Int)?
    var lastPlayed: Date?
    var imageURL: URL?
    
    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.fileName = url.lastPathComponent
        
        var title = url.deletingPathExtension().lastPathComponent
        self.imageURL = StaticWallpaperUtil.generateImageFile(from: self.url)!
        guard let index = title.firstIndex(of: "_") else {
            self.title = title
            return
        }
        self.title = String(title[title.index(after: index)...])
    }
    
    struct Resolution: Codable {
        let width: Int
        let height: Int
    }
    
    var resolutionStruct: Resolution? {
        guard let resolution = resolution else { return nil }
        return Resolution(width: resolution.width, height: resolution.height)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, url, title, fileName, duration, fileSize, resolutionStruct, lastPlayed, imageURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        url = try container.decode(URL.self, forKey: .url)
        title = try container.decode(String.self, forKey: .title)
        fileName = try container.decode(String.self, forKey: .fileName)
        duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
        fileSize = try container.decodeIfPresent(Int64.self, forKey: .fileSize)
        lastPlayed = try container.decodeIfPresent(Date.self, forKey: .lastPlayed)
        let defaultImageURL = Bundle.main.url(forResource: "images-no", withExtension: "png")
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL) ?? defaultImageURL
        
        
        if let resStruct = try container.decodeIfPresent(Resolution.self, forKey: .resolutionStruct) {
            resolution = (width: resStruct.width, height: resStruct.height)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(url, forKey: .url)
        try container.encode(title, forKey: .title)
        try container.encode(fileName, forKey: .fileName)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(fileSize, forKey: .fileSize)
        try container.encodeIfPresent(lastPlayed, forKey: .lastPlayed)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        
        if let resStruct = resolutionStruct {
            try container.encode(resStruct, forKey: .resolutionStruct)
        }
    }
}
