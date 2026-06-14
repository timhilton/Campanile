import SwiftUI

struct PreferencesView: View {
    @AppStorage("quietHoursEnabled") private var quietHoursEnabled = false
    @AppStorage("quietHoursStart") private var quietHoursStartInterval: Double = 23 * 3600
    @AppStorage("quietHoursEnd") private var quietHoursEndInterval: Double = 7 * 3600

    private var quietHoursStart: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSinceReferenceDate: quietHoursStartInterval) },
            set: { quietHoursStartInterval = $0.timeIntervalSinceReferenceDate }
        )
    }

    private var quietHoursEnd: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSinceReferenceDate: quietHoursEndInterval) },
            set: { quietHoursEndInterval = $0.timeIntervalSinceReferenceDate }
        )
    }

    var body: some View {
        Form {
            Toggle("Enable Quiet Hours", isOn: $quietHoursEnabled)
            if quietHoursEnabled {
                DatePicker("From:", selection: quietHoursStart, displayedComponents: .hourAndMinute)
                DatePicker("To:", selection: quietHoursEnd, displayedComponents: .hourAndMinute)
            }
        }
        .padding()
        .frame(width: 280)
    }
}
