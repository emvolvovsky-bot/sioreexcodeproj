//
//  TalentMediaView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct TalentMediaView: View {
    let hostId: String
    @State private var talentMedia: [TalentMediaItem] = []
    @State private var isLoading = true
    @State private var selectedMedia: TalentMediaItem?

    private let networkService = NetworkService()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                } else if talentMedia.isEmpty {
                    emptyStateView
                } else {
                    mediaGridView
                }
            }
            .navigationTitle("Talent Media")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadTalentMedia()
            }
            .sheet(item: $selectedMedia) { media in
                TalentMediaViewer(media: media)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.l) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(Color.sioreeLightGrey.opacity(0.4))

            VStack(spacing: Theme.Spacing.s) {
                Text("No talent media yet")
                    .font(.sioreeH3)
                    .foregroundColor(.sioreeWhite)

                Text("Talent clips and photos from your events will appear here")
                    .font(.sioreeBody)
                    .foregroundColor(Color.sioreeLightGrey.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private var mediaGridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Theme.Spacing.m),
                    GridItem(.flexible(), spacing: Theme.Spacing.m),
                    GridItem(.flexible(), spacing: Theme.Spacing.m)
                ],
                spacing: Theme.Spacing.m
            ) {
                ForEach(talentMedia) { media in
                    ZStack(alignment: .bottomLeading) {
                        if let url = URL(string: media.imageUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(Color.sioreeCharcoal)
                                        .overlay(
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                                        )
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure:
                                    Rectangle()
                                        .fill(Color.sioreeCharcoal)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundColor(.sioreeLightGrey)
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
                                    Image(systemName: "photo")
                                        .foregroundColor(.sioreeLightGrey)
                                )
                        }
                    }
                    .frame(height: 120)
                    .cornerRadius(Theme.CornerRadius.small)
                    .shadow(color: Color.black.opacity(0.3), radius: 4)
                    .onTapGesture {
                        selectedMedia = media
                    }
                }
            }
            .padding(.all, Theme.Spacing.m)
        }
    }

    private func loadTalentMedia() {
        isLoading = true

        networkService.fetchTalentMediaForHost(hostId: hostId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        print("Error loading talent media: \(error)")
                    }
                },
                receiveValue: { media in
                    self.talentMedia = media
                }
            )
            .store(in: &cancellables)
    }

    @State private var cancellables = Set<AnyCancellable>()
}

struct TalentMediaItem: Identifiable, Codable {
    let id: String
    let eventId: String
    let eventTitle: String
    let talentId: String
    let talentName: String
    let imageUrl: String
    let uploadedAt: Date
}

struct TalentMediaViewer: View {
    let media: TalentMediaItem
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.sioreeBlack.ignoresSafeArea()

            VStack {
                // Header with talent and event info
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(media.talentName)
                                .font(.sioreeH4)
                                .foregroundColor(.sioreeWhite)
                            Text(media.eventTitle)
                                .font(.sioreeBodySmall)
                                .foregroundColor(.sioreeLightGrey)
                        }
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.sioreeWhite)
                                .font(.system(size: 20, weight: .medium))
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.top, Theme.Spacing.m)

                // Media display
                if let url = URL(string: media.imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .failure:
                            Image(systemName: "photo")
                                .font(.system(size: 64))
                                .foregroundColor(.sioreeLightGrey)
                        @unknown default:
                            Image(systemName: "photo")
                                .font(.system(size: 64))
                                .foregroundColor(.sioreeLightGrey)
                        }
                    }
                }

                Spacer()
            }
        }
    }
}
