//
//  TimexoWidgetBundle.swift
//  TimexoWidget
//
//  Created by Chmil Oleksandr on 24.08.26.
//

import WidgetKit
import SwiftUI

@main
struct TimexoWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimexoWidget()
        TimexoHorizontalWidget()
        if #available(iOS 16.1, *) {
            TimexoWidgetLiveActivity()
        }
        if #available(iOS 18.0, *) {
            TimexoWidgetControl()
        }
    }
}
