//
//  TalentEventsWorkedView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct TalentEventsWorkedView: View {
    @StateObject private var viewModel = TalentProfileViewModel()
    @State private var selectedEvent: Event? = nil
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.95), Color.sioreeCharcoal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .sioreeIcyBlue))
                } else {
                    ScrollView {
                        VStack(spacing: Theme.Spacing.l) {
                            Text("Event History")
                                .font(.sioreeH2)
                                .foregroundColor(Color.sioreeWhite)
                                .padding(.top, Theme.Spacing.m)

                            if viewModel.events.isEmpty {
                                VStack(spacing: Theme.Spacing.m) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.system(size: 60))
                                        .foregroundColor(Color.sioreeLightGrey.opacity(0.5))
                                    Text("No events worked at yet")
                                        .font(.sioreeH3)
                                        .foregroundColor(Color.sioreeWhite)
                                    Text("Your completed events and clips will appear here")
                                        .font(.sioreeBody)
                                        .foregroundColor(Color.sioreeLightGrey.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.xxl)
                            } else {
                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible(), spacing: Theme.Spacing.m),
                                        GridItem(.flexible(), spacing: Theme.Spacing.m)
                                    ],
                                    spacing: Theme.Spacing.m
                                ) {
                                    ForEach(viewModel.events, id: \.id) { event in
                                        EventCardGridItem(event: event)
                                            .onTapGesture {
                                                selectedEvent = event
                                            }
                                            .contextMenu {
                                                Button(action: {
                                                    selectedEvent = event
                                                }) {
                                                    Label("Add Clips", systemImage: "video.fill")
                                                }
                                            }
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.m)
                            }
                        }
                        .padding(.bottom, Theme.Spacing.xl)
                    }
                }
            }
            .navigationTitle("Event History")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedEvent) { event in
                AddTalentClipsView(event: event)
                    .environmentObject(authViewModel)
            }
            .onAppear {
                viewModel.setAuthViewModel(authViewModel)
                viewModel.loadProfile()
            }
        }
    }
}
