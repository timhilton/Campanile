import AVFoundation

enum ChimeType {
    case hour(Int)
    case quarterHour
    case halfHour
    case threeQuarterHour
}

class AudioPlayer {
    private var player: AVAudioPlayer?

    func play(_ chime: ChimeType) {
        switch chime {
        case .hour(let count):
            strikeHour(times: count)
        case .quarterHour:
            playFile(named: "quarterhour")
        case .halfHour:
            playFile(named: "halfhour")
        case .threeQuarterHour:
            playFile(named: "threequarterhour")
        }
    }

    func setVolume(_ volume: Float) {
        UserDefaults.standard.set(volume, forKey: "bellVolume")
    }

    private func strikeHour(times: Int) {
        for i in 0..<times {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.5) {
                self.playFile(named: "bell")
            }
        }
    }

    private func isQuietHours() -> Bool {
        guard UserDefaults.standard.bool(forKey: "quietHoursEnabled") else { return false }

        let calendar = Calendar.current
        let now = Date()
        let current = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let start = minutesFromInterval(UserDefaults.standard.double(forKey: "quietHoursStart"))
        let end = minutesFromInterval(UserDefaults.standard.double(forKey: "quietHoursEnd"))

        return start < end ? current >= start && current < end : current >= start || current < end
    }

    private func minutesFromInterval(_ interval: Double) -> Int {
        let date = Date(timeIntervalSinceReferenceDate: interval)
        let calendar = Calendar.current
        return calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    }

    private func playFile(named name: String) {
        guard !isMuted, !isQuietHours() else { return }

        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            print("Missing audio file: \(name).wav")
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = volume
            player?.play()
        } catch {
            print("Audio playback error: \(error)")
        }
    }

    private var isMuted: Bool {
        UserDefaults.standard.bool(forKey: "isMuted")
    }

    private var volume: Float {
        let stored = UserDefaults.standard.float(forKey: "bellVolume")
        return stored == 0 ? 1.0 : stored
    }
}
