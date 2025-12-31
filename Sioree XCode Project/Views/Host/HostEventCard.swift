//
//  HostEventCard.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct HostEventCard: View {
    let event: Event
    let status: String
    let onTap: () -> Void
    @State private var showDetail = false
    
    private var priceText: String {
        if let price = event.ticketPrice, price > 0 {
            return String(format: "$%.0f", price)
        } else {
            return "FREE"
        }
    }
    
    var body: some View {
        Button(action: {
            showDetail = true
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Image placeholder with status badge
                ZStack {
                    Color.sioreeLightGrey.opacity(0.3)
                        .frame(height: 200)
                    
                    // Image icon centered
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                    
                    // Status badge in top right
                    VStack {
                        HStack {
                            Spacer()
                            StatusChip(status: status)
                                .padding(Theme.Spacing.s)
                        }
                        Spacer()
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text(event.title)
                        .font(.sioreeH4)
                        .foregroundColor(Color.sioreeWhite)
                    
                    HStack {
                        Text(event.hostName)
                            .font(.sioreeBodySmall)
                            .foregroundColor(Color.sioreeLightGrey)
                        
                        Text("•")
                            .foregroundColor(Color.sioreeLightGrey.opacity(0.5))
                        
                        Text(event.location)
                            .font(.sioreeBodySmall)
                            .foregroundColor(Color.sioreeLightGrey)
                    }
                    
                    HStack {
                        Text(event.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.sioreeBodySmall)
                            .foregroundColor(Color.sioreeLightGrey)
                        
                        Spacer()
                        
                        Text(priceText)
                            .font(.sioreeH4)
                            .foregroundColor(Color.sioreeIcyBlue)
                    }
                }
                .padding(Theme.Spacing.m)
                .background(Color.sioreeBlack)
            }
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 2)
            )
        }
        .sheet(isPresented: $showDetail) {
            EventDetailPlaceholderView(event: event)
        }
    }
}

struct HostEventCardGrid: View {
    let event: Event
    let onTap: () -> Void
    @State private var attendeePhotos: [String] = []
    @State private var isLoadingPhotos = true

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Photo collage background (same style as partier profile)
            ZStack {
                if !attendeePhotos.isEmpty {
                    // Display attendee photos in collage
                    GeometryReader { geometry in
                        ZStack {
                            // Display up to 4 photos in a collage
                            ForEach(0..<min(attendeePhotos.count, 4), id: \.self) { index in
                                if let url = URL(string: attendeePhotos[index]) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: collageSize(for: index, in: geometry.size).width,
                                                       height: collageSize(for: index, in: geometry.size).height)
                                                .clipped()
                                                .position(collagePosition(for: index, in: geometry.size))
                                                .rotationEffect(.degrees(collageRotation(for: index)))
                                        default:
                                            EmptyView()
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else if !isLoadingPhotos {
                    // No photos - show event image or placeholder
                    if let imageUrl = event.images.first, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.sioreeCharcoal)
                                    .overlay(
                                        Image(systemName: "party.popper.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                                    )
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Rectangle()
                                    .fill(Color.sioreeCharcoal)
                                    .overlay(
                                        Image(systemName: "party.popper.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(Color.sioreeLightGrey)
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(Color.sioreeCharcoal)
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(Color.sioreeCharcoal)
                            .overlay(
                                Image(systemName: "party.popper.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                            )
                    }
                } else {
                    // Loading placeholder
                    Rectangle()
                        .fill(Color.sioreeCharcoal)
                        .overlay(
                            ProgressView()
                                .tint(Color.sioreeIcyBlue)
                        )
                }
            }
            .frame(height: 180)
            .cornerRadius(Theme.CornerRadius.medium)
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)

            // Event info overlay (same style as partier profile)
            VStack(alignment: .leading, spacing: 2) {
                Spacer()
                Text(event.title)
                    .font(.sioreeCaption)
                    .foregroundColor(Color.sioreeWhite)
                    .lineLimit(1)
                    .shadow(color: Color.black.opacity(0.8), radius: 2)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(Color.sioreeLightGrey.opacity(0.9))
                    Text(event.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.sioreeCaption)
                        .foregroundColor(Color.sioreeLightGrey.opacity(0.9))
                }
                .shadow(color: Color.black.opacity(0.8), radius: 2)

                // Photo count indicator for hosted events
                if !attendeePhotos.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color.sioreeIcyBlue.opacity(0.9))
                        Text("\(attendeePhotos.count)")
                            .font(.sioreeCaption)
                            .foregroundColor(Color.sioreeIcyBlue.opacity(0.9))
                    }
                    .shadow(color: Color.black.opacity(0.8), radius: 2)
                }
            }
            .padding(Theme.Spacing.s)
        }
        .onTapGesture {
            onTap()
        }
        .onAppear {
            loadAttendeePhotos()
        }
    }

    private func eventStatusString(for event: Event) -> String {
        if event.date < Date() {
            return "Ended"
        } else {
            return "Upcoming"
        }
    }

    private func loadAttendeePhotos() {
        isLoadingPhotos = true

        // Try to load photos from API first
        let networkService = NetworkService()
        networkService.fetchPostsForEvent(eventId: event.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoadingPhotos = false
                    if case .failure = completion {
                        // Fallback to local storage
                        self.loadPhotosFromLocalStorage()
                    }
                },
                receiveValue: { posts in
                    // Extract all images from posts
                    self.attendeePhotos = posts.flatMap { $0.images }
                }
            )
            .store(in: &cancellables)
    }

    private func loadPhotosFromLocalStorage() {
        let storageKey = "event_photos_\(event.id)"
        let storedPhotos = UserDefaults.standard.array(forKey: storageKey) as? [[String: Any]] ?? []

        let images = storedPhotos.compactMap { photoData -> [String]? in
            return photoData["images"] as? [String]
        }.flatMap { $0 }

        self.attendeePhotos = images
    }

    // Collage layout helpers
    private func collageSize(for index: Int, in totalSize: CGSize) -> CGSize {
        let baseSize = min(totalSize.width, totalSize.height) * 0.4
        switch index {
        case 0: return CGSize(width: baseSize * 1.2, height: baseSize * 1.2) // Main photo
        case 1: return CGSize(width: baseSize * 0.8, height: baseSize * 0.8) // Secondary
        case 2: return CGSize(width: baseSize * 0.6, height: baseSize * 0.6) // Small
        case 3: return CGSize(width: baseSize * 0.5, height: baseSize * 0.5) // Smallest
        default: return CGSize(width: baseSize * 0.4, height: baseSize * 0.4)
        }
    }

    private func collagePosition(for index: Int, in totalSize: CGSize) -> CGPoint {
        let centerX = totalSize.width / 2
        let centerY = totalSize.height / 2

        switch index {
        case 0: return CGPoint(x: centerX - 20, y: centerY - 20) // Slightly offset main
        case 1: return CGPoint(x: centerX + 40, y: centerY + 20) // Bottom right
        case 2: return CGPoint(x: centerX - 50, y: centerY + 30) // Bottom left
        case 3: return CGPoint(x: centerX + 20, y: centerY - 40) // Top right
        default: return CGPoint(x: centerX, y: centerY)
        }
    }

    private func collageRotation(for index: Int) -> Double {
        switch index {
        case 0: return 0
        case 1: return 5
        case 2: return -8
        case 3: return 12
        default: return 0
        }
    }

    @State private var cancellables = Set<AnyCancellable>()
}

#Preview {
    HostEventCard(
        event: Event(
            id: "1",
            title: "Sample Event",
            description: "A sample event",
            hostId: "h1",
            hostName: "Sample Host",
            date: Date(),
            time: Date(),
            location: "Sample Location",
            ticketPrice: 25.0
        ),
        status: "On sale",
        onTap: {}
    )
    .padding()
    .background(Color.sioreeBlack)
}

#Preview("Grid Card") {
    HostEventCardGrid(
        event: Event(
            id: "1",
            title: "Summer Music Festival",
            description: "A sample event",
            hostId: "h1",
            hostName: "Sample Host",
            date: Date(),
            time: Date(),
            location: "Sample Location",
            ticketPrice: 25.0
        ),
        onTap: {}
    )
    .frame(width: 180, height: 220)
    .padding()
    .background(Color.sioreeBlack)
}

