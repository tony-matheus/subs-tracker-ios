//
//  ChartWidgetBundle.swift
//  ChartWidget
//
//  Created by Tony Matheus on 02/07/26.
//

import WidgetKit
import SwiftUI

@main
struct ChartWidgetBundle: WidgetBundle {
    var body: some Widget {
        ChartWidget()
        ChartWidgetControl()
        ChartWidgetLiveActivity()
    }
}
