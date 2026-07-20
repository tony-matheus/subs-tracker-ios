//
//  ChartWidgetLiveActivity.swift
//  ChartWidget
//
//  Created by Tony Matheus on 02/07/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ChartWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ChartWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ChartWidgetAttributes.self) { context in
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

extension ChartWidgetAttributes {
    fileprivate static var preview: ChartWidgetAttributes {
        ChartWidgetAttributes(name: "World")
    }
}

extension ChartWidgetAttributes.ContentState {
    fileprivate static var smiley: ChartWidgetAttributes.ContentState {
        ChartWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ChartWidgetAttributes.ContentState {
         ChartWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ChartWidgetAttributes.preview) {
   ChartWidgetLiveActivity()
} contentStates: {
    ChartWidgetAttributes.ContentState.smiley
    ChartWidgetAttributes.ContentState.starEyes
}
