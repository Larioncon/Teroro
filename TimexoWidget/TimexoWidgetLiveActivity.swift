//
//  TimexoWidgetLiveActivity.swift
//  TimexoWidget
//
//  Created by Chmil Oleksandr on 24.08.26.
//

import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
struct TimexoWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

@available(iOS 16.1, *)
struct TimexoWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimexoWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

@available(iOS 16.1, *)
extension TimexoWidgetAttributes {
    fileprivate static var preview: TimexoWidgetAttributes {
        TimexoWidgetAttributes(name: "World")
    }
}

@available(iOS 16.1, *)
extension TimexoWidgetAttributes.ContentState {
    fileprivate static var smiley: TimexoWidgetAttributes.ContentState {
        TimexoWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TimexoWidgetAttributes.ContentState {
         TimexoWidgetAttributes.ContentState(emoji: "🤩")
     }
}

//#Preview("Notification", as: .content, using: TimexoWidgetAttributes.preview) {
//   TimexoWidgetLiveActivity()
//} contentStates: {
//    TimexoWidgetAttributes.ContentState.smiley
//    TimexoWidgetAttributes.ContentState.starEyes
//}
