//
//  TalentCard.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct TalentCard: View {
    let talent: TalentListing
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                HStack(spacing: Theme.Spacing.m) {
                    // Avatar Placeholder
                    ZStack {
                        Circle()
                            .fill(Color.sioreeLightGrey.opacity(0.3))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: talent.imageName)
                            .font(.system(size: 30))
                            .foregroundColor(Color.sioreeIcyBlue)
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(talent.name)
                            .font(.sioreeH4)
                            .foregroundColor(Color.sioreeWhite)
                        
                        Text(talent.roleText)
                            .font(.sioreeBodySmall)
                            .foregroundColor(Color.sioreeLightGrey)
                        
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color.sioreeWarmGlow)
                            
                            Text(String(format: "%.1f", talent.rating))
                                .font(.sioreeBodySmall)
                                .foregroundColor(Color.sioreeLightGrey)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                        Text(talent.rateText)
                            .font(.sioreeH4)
                            .foregroundColor(Color.sioreeIcyBlue)
                        
                        Text(talent.location)
                            .font(.sioreeCaption)
                            .foregroundColor(Color.sioreeLightGrey)
                    }
                }
            }
            .padding(Theme.Spacing.m)
            .background(Color.sioreeLightGrey.opacity(0.1))
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
            )
        }
    }
}

#Preview {
    TalentCard(
        talent: MockData.sampleTalent[0],
        onTap: {}
    )
    .padding()
    .background(Color.sioreeBlack)
}

