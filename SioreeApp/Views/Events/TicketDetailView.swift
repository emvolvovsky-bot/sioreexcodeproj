//
//  TicketDetailView.swift
//  Sioree
//
//  Detailed view for a ticket
//

import SwiftUI

struct TicketDetailView: View {
    let ticket: Ticket
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGlow
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Ticket Display
                        VStack(spacing: Theme.Spacing.xl) {
                            // User Name
                            Text(userName)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.sioreeWhite)
                                .padding(.top, Theme.Spacing.xxl)
                            
                            // Cool Graphic
                            ticketGraphic
                            
                            // Instruction Text
                            Text("Show this to the event host when entering")
                                .font(.sioreeBody)
                                .foregroundColor(.sioreeLightGrey)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.Spacing.l)
                        }
                        .padding(.top, Theme.Spacing.xl)
                        
                        // Ticket Info
                        ticketInfoCard
                            .padding(.horizontal, Theme.Spacing.l)
                    }
                    .padding(.vertical, Theme.Spacing.l)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    private var userName: String {
        authViewModel.currentUser?.name ?? "Guest"
    }
    
    private var backgroundGlow: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.sioreeBlack,
                    Color.sioreeBlack.opacity(0.98),
                    Color.sioreeCharcoal.opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Circle()
                .fill(Color.sioreeIcyBlue.opacity(0.25))
                .frame(width: 360, height: 360)
                .blur(radius: 120)
                .offset(x: -120, y: -320)
            
            Circle()
                .fill(Color.sioreeIcyBlue.opacity(0.2))
                .frame(width: 420, height: 420)
                .blur(radius: 140)
                .offset(x: 160, y: 220)
        }
    }
    
    private var ticketGraphic: some View {
        ZStack {
            // Outer glow circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.sioreeIcyBlue.opacity(0.3),
                            Color.sioreeIcyBlue.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 240, height: 240)
                .blur(radius: 20)
            
            // Middle ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.sioreeIcyBlue.opacity(0.6),
                            Color.sioreeIcyBlue.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 200, height: 200)
            
            // Inner circle with ticket icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.sioreeIcyBlue.opacity(0.2),
                                Color.sioreeIcyBlue.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                
                // Ticket icon
                Image(systemName: "ticket.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.sioreeIcyBlue,
                                Color.sioreeIcyBlue.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.sioreeIcyBlue.opacity(0.5), radius: 12)
            }
            
            // Decorative dots around the circle
            ForEach(0..<8) { index in
                Circle()
                    .fill(Color.sioreeIcyBlue.opacity(0.4))
                    .frame(width: 8, height: 8)
                    .offset(
                        x: cos(Double(index) * .pi / 4) * 110,
                        y: sin(Double(index) * .pi / 4) * 110
                    )
            }
        }
        .frame(height: 240)
    }
    
    private var ticketInfoCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text(ticket.eventTitle)
                .font(.sioreeH3)
                .foregroundColor(.sioreeWhite)
            
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: "calendar")
                    .foregroundColor(.sioreeIcyBlue.opacity(0.8))
                Text(ticket.eventDate.formatted(date: .long, time: .shortened))
                    .font(.sioreeBody)
            }
            .foregroundColor(.sioreeLightGrey)
            
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.sioreeIcyBlue.opacity(0.8))
                Text(ticket.eventLocation)
                    .font(.sioreeBody)
            }
            .foregroundColor(.sioreeLightGrey)
            
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: "person.fill")
                    .foregroundColor(.sioreeIcyBlue.opacity(0.8))
                Text("Host: \(ticket.hostName)")
                    .font(.sioreeBody)
            }
            .foregroundColor(.sioreeLightGrey)
            
            Divider()
                .background(Color.sioreeLightGrey.opacity(0.3))
            
            HStack {
                Text("Ticket #\(ticket.id.prefix(8))")
                    .font(.sioreeBodySmall)
                    .foregroundColor(.sioreeLightGrey)
                
                Spacer()
                
                StatusBadge(status: ticket.status)
            }
        }
        .padding(Theme.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.sioreeIcyBlue.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.sioreeIcyBlue.opacity(0.16), radius: 24, x: 0, y: 12)
        )
    }
}

struct StatusBadge: View {
    let status: Ticket.TicketStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.sioreeCaption)
            .fontWeight(.semibold)
            .foregroundColor(colorForStatus)
            .padding(.horizontal, Theme.Spacing.s)
            .padding(.vertical, 4)
            .background(backgroundColorForStatus)
            .cornerRadius(Theme.CornerRadius.small)
    }
    
    private var colorForStatus: Color {
        switch status {
        case .valid: return .green
        case .used: return .sioreeLightGrey
        case .cancelled: return .red
        case .expired: return .orange
        }
    }
    
    private var backgroundColorForStatus: Color {
        switch status {
        case .valid: return Color.green.opacity(0.2)
        case .used: return Color.sioreeLightGrey.opacity(0.2)
        case .cancelled: return Color.red.opacity(0.2)
        case .expired: return Color.orange.opacity(0.2)
        }
    }
}

#Preview {
    TicketDetailView(ticket: Ticket(
        eventId: "e1",
        userId: "u1",
        eventTitle: "Halloween Mansion Party",
        eventDate: Date(),
        eventLocation: "Bel Air, CA",
        hostName: "LindaFlora",
        price: 75.0
    ))
    .environmentObject(AuthViewModel())
}


