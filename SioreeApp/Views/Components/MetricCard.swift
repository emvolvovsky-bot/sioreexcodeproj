//
//  MetricCard.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let progress: Double?
    
    init(title: String, value: String, subtitle: String? = nil, progress: Double? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.progress = progress
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text(title)
                .font(.sioreeBodySmall)
                .foregroundColor(Color.sioreeLightGrey)
            
            Text(value)
                .font(.sioreeH2)
                .foregroundColor(Color.sioreeWhite)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.sioreeCaption)
                    .foregroundColor(Color.sioreeLightGrey.opacity(0.7))
            }
            
            if let progress = progress {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.sioreeLightGrey.opacity(0.2))
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(Color.sioreeIcyBlue)
                            .frame(width: geometry.size.width * CGFloat(progress), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(Theme.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sioreeLightGrey.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
        )
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.m) {
        MetricCard(title: "Total Impressions", value: "125K", subtitle: "+12% from last month")
        MetricCard(title: "Progress", value: "75%", progress: 0.75)
    }
    .padding()
    .background(Color.sioreeBlack)
}

