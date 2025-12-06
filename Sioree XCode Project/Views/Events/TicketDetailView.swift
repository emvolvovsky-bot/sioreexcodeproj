//
//  TicketDetailView.swift
//  Sioree
//
//  Detailed view for a ticket with QR code
//

import SwiftUI

struct TicketDetailView: View {
    let ticket: Ticket
    @Environment(\.dismiss) var dismiss
    @State private var qrCodeImage: UIImage?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle gradient on black background
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        // QR Code
                        VStack(spacing: Theme.Spacing.m) {
                            if let qrString = ticket.qrCodeData {
                                QRCodeView(qrString: qrString, size: 250)
                            } else {
                                // Generate QR code if not present
                                if let qrImage = QRCodeService.shared.generateTicketQRCode(
                                    ticketId: ticket.id,
                                    eventId: ticket.eventId,
                                    userId: ticket.userId
                                ) {
                                    Image(uiImage: qrImage)
                                        .interpolation(.none)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 250, height: 250)
                                        .background(Color.white)
                                        .cornerRadius(Theme.CornerRadius.medium)
                                        .padding(Theme.Spacing.s)
                                        .background(Color.white)
                                        .cornerRadius(Theme.CornerRadius.medium)
                                }
                            }
                            
                            Text("Show this QR code at the event")
                                .font(.sioreeBodySmall)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        .padding(.top, Theme.Spacing.l)
                        
                        // Ticket Info
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            Text(ticket.eventTitle)
                                .font(.sioreeH2)
                                .foregroundColor(.sioreeWhite)
                            
                            HStack {
                                Image(systemName: "calendar")
                                Text(ticket.eventDate.formatted(date: .long, time: .shortened))
                                    .font(.sioreeBody)
                            }
                            .foregroundColor(.sioreeLightGrey)
                            
                            HStack {
                                Image(systemName: "location.fill")
                                Text(ticket.eventLocation)
                                    .font(.sioreeBody)
                            }
                            .foregroundColor(.sioreeLightGrey)
                            
                            HStack {
                                Image(systemName: "person.fill")
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
                        .background(Color.sioreeLightGrey.opacity(0.1))
                        .cornerRadius(Theme.CornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
                        )
                        .padding(.horizontal, Theme.Spacing.l)
                    }
                    .padding(.vertical, Theme.Spacing.l)
                }
            }
            .navigationTitle("Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
        }
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
}


