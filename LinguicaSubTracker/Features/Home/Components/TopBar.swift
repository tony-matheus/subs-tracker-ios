//
//  TopBar.swift
//  LinguicaSubTracker
//
//  Created by Tony Matheus on 23/04/26.
//

import SwiftUI

struct TopBar: View {
    var body: some View {
        HStack {
            Menu {
                Button("All Subscriptions") {}
                Button("Active") {}
            } label: {
                HStack(spacing: 4) {
                    Text("All Subs")
                        .typography(.titleSmall)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.gray)
            }

            Spacer()

            HStack(spacing: 16) {
                Button {
                    print("Search Tapped")
                } label: {
                    Image(systemName: "magnifyingglass")
                        .iconStyle()
                }

                Button {
                    print("Stats Tapped")
                } label: {
                    Image(systemName: "chart.bar")
                        .iconStyle()
                }

                Button {
                    print("Settings tapped")
                } label: {
                    Image(systemName: "gearshape")
                        .iconStyle()
                }
            }
        }
        .padding()
    }
}
