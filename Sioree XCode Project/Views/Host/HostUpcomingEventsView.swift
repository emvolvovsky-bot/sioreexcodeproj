//
//  HostUpcomingEventsView.swift
//  Sioree
//
//  Created by Sioree Team
//
//
import SwiftUI
import Combine

struct HostUpcomingEventsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var profileViewModel = ProfileViewModel(userId: nil, useAttendedEvents: false)
    @State private var showNewEvent = false
    
    private var upcomingEvents: [Event] {
        profileViewModel.upcomingEvents
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.sioreeBlack,
                Color.sioreeBlack.opacity(0.98),
                Color.sioreeCharcoal.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(Color.sioreeLightGrey.opacity(0.4))
            VStack(spacing: Theme.Spacing.s) {
                Text("No upcoming events")
                    .font(.sioreeH3)
                    .foregroundColor(Color.sioreeWhite)
                Text("Create your next event!")
                    .font(.sioreeBody)
                    .foregroundColor(Color.sioreeLightGrey.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.vertical, Theme.Spacing.xl)
        .padding(.horizontal, Theme.Spacing.l)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                if profileViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if upcomingEvents.isEmpty {
                    emptyStateView
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: Theme.Spacing.m) {
                            ForEach(upcomingEvents) { event in
                                NavigationLink(destination: EventDetailView(eventId: event.id, isTalentMapMode: false).environmentObject(authViewModel)) {
                                    NightEventCard(event: event, accent: .sioreeIcyBlue, actionLabel: "Edit Details")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.vertical, Theme.Spacing.m)
                        .padding(.bottom, Theme.Spacing.xl)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .bottomTrailing) {
                Button(action: {
                    showNewEvent = true
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.sioreeIcyBlue.opacity(0.4),
                                        Color.sioreeIcyBlue.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 40
                                )
                            )
                            .frame(width: 80, height: 80)
                            .blur(radius: 8)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.sioreeIcyBlue.opacity(0.9),
                                        Color.sioreeIcyBlue
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                            .overlay(
                                Circle()
                                    .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.sioreeIcyBlue.opacity(0.5), radius: 16, x: 0, y: 8)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.sioreeWhite)
                    }
                }
                .padding(.trailing, Theme.Spacing.l)
                .padding(.bottom, 100)
            }
            .sheet(isPresented: $showNewEvent) {
                EventCreateView(onEventCreated: { event in
                    print("📡 HostUpcomingEventsView received event creation callback: \(event.title)")
                }, currentUserLocation: authViewModel.currentUser?.location)
                .environmentObject(authViewModel)
            }
            .onAppear {
                profileViewModel.setAuthViewModel(authViewModel)
                profileViewModel.loadProfile()
            }
            .onChange(of: authViewModel.currentUser?.id) { _ in
                profileViewModel.setAuthViewModel(authViewModel)
                profileViewModel.loadProfile()
            }
        }
    }
}

#Preview {
    HostUpcomingEventsView()
        .environmentObject(AuthViewModel())
}

