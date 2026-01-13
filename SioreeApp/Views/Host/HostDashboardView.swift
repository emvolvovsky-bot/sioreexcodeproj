//
//  HostDashboardView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI

struct HostDashboardView: View {
    @StateObject private var bookingViewModel = BookingViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.sioreeWhite.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.l) {
                        // Stats Cards
                        HStack(spacing: Theme.Spacing.m) {
                            StatCard(title: "Upcoming Events", value: "12")
                            StatCard(title: "Total Revenue", value: "$5.2K")
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        
                        // Quick Actions
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            Text("Quick Actions")
                                .font(.sioreeH4)
                                .foregroundColor(Color.sioreeCharcoal)
                                .padding(.horizontal, Theme.Spacing.m)
                            
                            HStack(spacing: Theme.Spacing.m) {
                                QuickActionButton(
                                    title: "Create Event",
                                    icon: "calendar",
                                    color: Color.sioreeIcyBlue
                                )
                                
                                QuickActionButton(
                                    title: "Book Talent",
                                    icon: "person.2",
                                    color: Color.sioreeWarmGlow
                                )
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                        }
                        
                        // Recent Bookings
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            Text("Recent Bookings")
                                .font(.sioreeH4)
                                .foregroundColor(Color.sioreeCharcoal)
                                .padding(.horizontal, Theme.Spacing.m)
                            
                            ForEach(bookingViewModel.bookings.prefix(5)) { booking in
                                BookingRow(booking: booking)
                                    .padding(.horizontal, Theme.Spacing.m)
                            }
                        }
                    }
                    .padding(.vertical, Theme.Spacing.m)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                bookingViewModel.loadBookings()
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(value)
                .font(.sioreeH2)
                .foregroundColor(Color.sioreeCharcoal)
            
            Text(title)
                .font(.sioreeBodySmall)
                .foregroundColor(Color.sioreeCharcoal.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.m)
        .cardStyle()
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: Theme.Spacing.s) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.sioreeBodySmall)
                    .foregroundColor(Color.sioreeCharcoal)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.m)
            .cardStyle()
        }
    }
}

struct BookingRow: View {
    let booking: Booking
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Booking #\(String(booking.id.prefix(8)))")
                    .font(.sioreeBody)
                    .foregroundColor(Color.sioreeCharcoal)
                
                Text(booking.date.formattedEventDate())
                    .font(.sioreeCaption)
                    .foregroundColor(Color.sioreeCharcoal.opacity(0.6))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                Text(Helpers.formatCurrency(booking.price))
                    .font(.sioreeBody)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.sioreeCharcoal)
                
                Text(booking.status.rawValue.capitalized)
                    .font(.sioreeCaption)
                    .foregroundColor(statusColor(booking.status))
            }
        }
        .padding(Theme.Spacing.m)
        .cardStyle()
    }
    
    private func statusColor(_ status: BookingStatus) -> Color {
        switch status {
        case .confirmed:
            return Color.sioreeSuccess
        case .requested:
            return Color.sioreeWarning
        case .accepted:
            return Color(hex: "007AFF") // Blue for accepted
        case .awaiting_payment:
            return Color.sioreeWarning
        case .declined:
            return Color.sioreeError
        case .expired:
            return Color.gray
        case .canceled:
            return Color.sioreeError
        case .completed:
            return Color.sioreeInfo
        }
    }
}

#Preview {
    HostDashboardView()
}

