//
//  TopBar.swift
//  LinguicaSubTracker
//
//  Created by Tony Matheus on 23/04/26.
//

import Foundation
import SwiftUI

struct TopBar: View {
    var body: some View {
        HStack {
            Menu {
                Button("All Subscriptions ") {}
                Button("Active") {}
            } label: {
                HStack {
                    Text("All Subs")
                    Image(systemName: "chevron.down")
                }
            }

            Spacer()

            HStack(spacing: 16) {
                Button {
                    print("Search Tapped")
                } label: {
                    Image(systemName: "magnifyingglass")
                }

                Button {
                    print("Stats Tapped")
                } label: {
                    Image(systemName: "chart.bar")
                }

                Button {
                    print("Settings tapped")
                } label: {
                    Image(systemName: "gearshape")
                }

            }
        }.padding()
    }
}
