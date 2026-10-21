//
//  AppIntent.swift
//  TimexoWidget
//
//  Created by Chmil Oleksandr on 24.08.26.
//

import WidgetKit
import AppIntents

@available(iOS 17.0, *)
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "widget.configuration.title" }
    static var description: IntentDescription { "widget.description.example" }

    // An example configurable parameter.
    @Parameter(title: "widget.configuration.favorite.emoji", default: "😃")
    var favoriteEmoji: String
}
