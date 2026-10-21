//
//  TimexoWidgetControl.swift
//  TimexoWidget
//
//  Created by Chmil Oleksandr on 24.08.26.
//

import AppIntents
import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct TimexoWidgetControl: ControlWidget {
    static let kind: String = "com.OleksaChmil.Timora.TimexoWidget"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                LocalizedStringResource("widget.control.start_timer", locale: WidgetAppLocale.current),
                isOn: value.isRunning,
                action: StartTimerIntent(value.name)
            ) { isRunning in
                Label {
                    Text(isRunning ? "widget.control.on" : "widget.control.off")
                } icon: {
                    Image(systemName: "timer")
                }
                .environment(\.locale, WidgetAppLocale.current)
            }
        }
        .displayName(LocalizedStringResource("widget.control.timer", locale: WidgetAppLocale.current))
        .description(LocalizedStringResource("widget.control.description", locale: WidgetAppLocale.current))
    }
}

@available(iOS 18.0, *)
extension TimexoWidgetControl {
    struct Value {
        var isRunning: Bool
        var name: String
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: TimerConfiguration) -> Value {
            TimexoWidgetControl.Value(isRunning: false, name: configuration.timerName)
        }

        func currentValue(configuration: TimerConfiguration) async throws -> Value {
            let isRunning = true // Check if the timer is running
            return TimexoWidgetControl.Value(isRunning: isRunning, name: configuration.timerName)
        }
    }
}

@available(iOS 18.0, *)
struct TimerConfiguration: ControlConfigurationIntent {
    static let title = LocalizedStringResource("widget.control.timer_configuration", locale: WidgetAppLocale.current)

    @Parameter(
        title: LocalizedStringResource("widget.control.timer_name", locale: WidgetAppLocale.current),
        default: "Timer"
    )
    var timerName: String
}

@available(iOS 18.0, *)
struct StartTimerIntent: SetValueIntent {
    static let title = LocalizedStringResource("widget.control.start_timer", locale: WidgetAppLocale.current)

    @Parameter(title: LocalizedStringResource("widget.control.timer_name", locale: WidgetAppLocale.current))
    var name: String

    @Parameter(title: LocalizedStringResource("widget.control.is_running", locale: WidgetAppLocale.current))
    var value: Bool

    init() {}

    init(_ name: String) {
        self.name = name
    }

    func perform() async throws -> some IntentResult {
        // Start the timer…
        return .result()
    }
}
