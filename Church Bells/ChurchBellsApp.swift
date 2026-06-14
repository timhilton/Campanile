import SwiftUI

@main
struct ChurchBellsApp: App {
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

	var body: some Scene {
		Settings { EmptyView() }
	}
}
