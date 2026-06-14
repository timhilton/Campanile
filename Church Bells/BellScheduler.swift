import AppKit
import Foundation

class BellScheduler {
    private var timer: Timer?
    private let audioPlayer = AudioPlayer()

    func start() {
        scheduleNextChime()
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    func setVolume(_ volume: Float) {
        audioPlayer.setVolume(volume)
    }

    private func scheduleNextChime() {
        let calendar = Calendar.current
        let now = Date()
        let minutes = calendar.component(.minute, from: now)
        let seconds = calendar.component(.second, from: now)
        let nanoseconds = calendar.component(.nanosecond, from: now)

        let chimeMinutes = [0, 15, 30, 45]
        let nextChime = chimeMinutes.first { $0 > minutes } ?? 60
        let minutesUntilChime = nextChime == 60 ? (60 - minutes) : (nextChime - minutes)
        let secondsUntilChime = Double(minutesUntilChime * 60) - Double(seconds) - (Double(nanoseconds) / 1_000_000_000)

        timer = Timer.scheduledTimer(withTimeInterval: secondsUntilChime, repeats: false) { [weak self] _ in
            self?.ringIfNeeded()
            self?.scheduleNextChime()
        }
    }

    private func ringIfNeeded() {
        let calendar = Calendar.current
        let now = Date()
        let minutes = calendar.component(.minute, from: now)
        let rawHour = calendar.component(.hour, from: now) % 12
        let displayHour = rawHour == 0 ? 12 : rawHour

        switch minutes {
        case 0:  audioPlayer.play(.hour(displayHour))
        case 15: audioPlayer.play(.quarterHour)
        case 30: audioPlayer.play(.halfHour)
        case 45: audioPlayer.play(.threeQuarterHour)
        default: break
        }
    }

    @objc private func handleWake() {
        timer?.invalidate()
        scheduleNextChime()
    }
}
