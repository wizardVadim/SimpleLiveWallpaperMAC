// Utilities/DesktopWindow.swift
import Cocoa
import AVFoundation
import CoreGraphics

final class DesktopWindow: NSWindow {

    // 🔁 Новый паттерн
    private var queuePlayer: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        configureWindow()
    }

    private func configureWindow() {
        self.level = NSWindow.Level(
            rawValue: Int(CGWindowLevelForKey(.desktopWindow))
        )

        self.collectionBehavior = [
            .stationary,
            .ignoresCycle,
            .canJoinAllSpaces
        ]

        self.isReleasedWhenClosed = false
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.contentView?.wantsLayer = true
    }

    // MARK: - Playback

    func playVideo(url: URL) {
        assert(Thread.isMainThread)

        stopPlayback()

        print("🎬 Воспроизведение видео:", url.lastPathComponent)

        let asset = AVAsset(url: url)
        let item = AVPlayerItem(asset: asset)

        let player = AVQueuePlayer()
        player.isMuted = true

        let looper = AVPlayerLooper(
            player: player,
            templateItem: item
        )

        let layer = AVPlayerLayer(player: player)
        layer.frame = contentView?.bounds ?? .zero
        layer.videoGravity = .resizeAspectFill

        contentView?.layer?.addSublayer(layer)

        self.queuePlayer = player
        self.looper = looper
        self.playerLayer = layer

        player.play()

        print("✅ Video is playing")
    }

    func stopPlayback() {
        assert(Thread.isMainThread)

        queuePlayer?.pause()

        // ❗ порядок важен
        looper = nil
        queuePlayer = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }

    var isPlaying: Bool {
        return queuePlayer?.rate != 0
    }

    deinit {
        print("♻️ DesktopWindow deinit")
    }
}
