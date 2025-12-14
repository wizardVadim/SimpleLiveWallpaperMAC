//
//  VideoPlayer.swift
//  SimpleLiveWallpaperMAC
//
//  Created by Вадим Вехов on 14.12.2025.
//

import AVFoundation
import Cocoa

extension NSView {
    func removeFromSuperviewSafely() {
        guard superview != nil else { return }
        removeFromSuperview()
    }
}

final class VideoPlayer: NSView {
    private var queuePlayer: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?

    var videoURL: URL? {
        didSet { playVideo() }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    private func playVideo() {
        guard let url = videoURL else { return }

        stopVideo()

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)

        let player = AVQueuePlayer()
        player.isMuted = true

        let looper = AVPlayerLooper(player: player, templateItem: item)

        let layer = AVPlayerLayer(player: player)
        layer.frame = bounds
        layer.videoGravity = .resizeAspectFill

        self.layer?.addSublayer(layer)

        self.queuePlayer = player
        self.looper = looper
        self.playerLayer = layer

        player.play()
    }

    func stopVideo() {
        playerLayer?.removeFromSuperlayer()

        queuePlayer?.pause()

        looper = nil
        queuePlayer = nil
        playerLayer = nil
    }


    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }
}
