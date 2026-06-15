import AppKit
import ServiceManagement
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var bellScheduler: BellScheduler?
    private var preferencesWindow: NSWindow?
    private var quietHoursStatusItem: NSMenuItem?
    
    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "bell", accessibilityDescription: "Church Bells")
        }

        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 50))

        let label = NSTextField(labelWithString: "Volume:")
        label.frame = NSRect(x: 12, y: 28, width: 60, height: 16)
        containerView.addSubview(label)

        let slider = NSSlider(value: 1.0, minValue: 0.0, maxValue: 1.0, target: self, action: #selector(volumeChanged(_:)))
        slider.floatValue = UserDefaults.standard.float(forKey: "bellVolume") == 0 ? 1.0 : UserDefaults.standard.float(forKey: "bellVolume")
        slider.frame = NSRect(x: 12, y: 8, width: 196, height: 20)
        containerView.addSubview(slider)

        let sliderItem = NSMenuItem()
        sliderItem.view = containerView

        let muteItem = NSMenuItem(title: "Mute", action: #selector(toggleMute), keyEquivalent: "m")
        muteItem.tag = 1

        let quietStatus = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        quietStatus.isEnabled = false
        quietStatus.isHidden = true
        quietHoursStatusItem = quietStatus

        let menu = NSMenu()
        menu.addItem(sliderItem)
        menu.addItem(muteItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quietStatus)
        menu.addItem(NSMenuItem(title: "Start at Login", action: #selector(toggleLoginItem), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem?.menu = menu

        bellScheduler = BellScheduler()
        bellScheduler?.start()

        if UserDefaults.standard.bool(forKey: "isMuted") {
            statusItem?.menu?.item(withTag: 1)?.title = "Unmute"
        }

        if SMAppService.mainApp.status == .enabled {
            statusItem?.menu?.item(withTitle: "Start at Login")?.state = .on
        }

        updateQuietHoursStatus()
        UserDefaults.standard.addObserver(self, forKeyPath: "quietHoursEnabled", options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "quietHoursStart", options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "quietHoursEnd", options: .new, context: nil)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    @objc private func volumeChanged(_ sender: NSSlider) {
        UserDefaults.standard.set(sender.floatValue, forKey: "bellVolume")
        bellScheduler?.setVolume(sender.floatValue)
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func toggleMute() {
        let isMuted = UserDefaults.standard.bool(forKey: "isMuted")
        UserDefaults.standard.set(!isMuted, forKey: "isMuted")
        if let muteItem = statusItem?.menu?.item(withTag: 1) {
            muteItem.title = isMuted ? "Mute" : "Unmute"
        }
    }

    @objc private func toggleLoginItem() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
                statusItem?.menu?.item(withTitle: "Start at Login")?.state = .off
            } else {
                try service.register()
                statusItem?.menu?.item(withTitle: "Start at Login")?.state = .on
            }
        } catch {
            print("Failed to toggle login item: \(error)")
        }
    }

    @objc private func showPreferences() {
        if preferencesWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 280, height: 200),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Campanile Preferences"
            window.contentView = NSHostingView(rootView: PreferencesView())
            window.center()
            preferencesWindow = window
        }
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func updateQuietHoursStatus() {
        let enabled = UserDefaults.standard.bool(forKey: "quietHoursEnabled")
        if enabled {
            let startDate = Date(timeIntervalSinceReferenceDate: UserDefaults.standard.double(forKey: "quietHoursStart"))
            let endDate = Date(timeIntervalSinceReferenceDate: UserDefaults.standard.double(forKey: "quietHoursEnd"))
            quietHoursStatusItem?.title = "Quiet Hours: \(formatTime(startDate)) - \(formatTime(endDate))"
            quietHoursStatusItem?.isHidden = false
        } else {
            quietHoursStatusItem?.isHidden = true
        }
    }

    private func formatTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "quietHoursEnabled" || keyPath == "quietHoursStart" || keyPath == "quietHoursEnd" {
            DispatchQueue.main.async {
                self.updateQuietHoursStatus()
            }
        }
    }
}
