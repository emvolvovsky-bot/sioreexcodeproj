//
//  HostMyEventsView.swift
//  Sioree
//
//  Created by Sioree Team
//
//
import SwiftUI
import Combine

struct HostMyEventsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var profileViewModel = ProfileViewModel(userId: nil, useAttendedEvents: false)
    @State private var showNewEvent = false
    @State private var selectedEventForDetail: Event? = nil
    @State private var selectedSegment: ProfileViewModel.HostProfileTab = .upcoming
    
    private var upcomingEvents: [Event] {
        profileViewModel.upcomingEvents
    }

    private var pastEvents: [Event] {
        profileViewModel.hostedEvents
    }

    private var visibleEvents: [Event] {
        selectedSegment == .upcoming ? upcomingEvents : pastEvents
    }
    
    private var backgroundGradient: some View {
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
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(Color.sioreeLightGrey.opacity(0.4))
            VStack(spacing: Theme.Spacing.s) {
                Text(selectedSegment == .upcoming ? "No upcoming events" : "No past events")
                    .font(.sioreeH3)
                    .foregroundColor(Color.sioreeWhite)
                Text(selectedSegment == .upcoming ? "Create your next event!" : "Completed events will appear here")
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
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Custom Segmented Control
                        customSegmentedControl
                            .padding(.horizontal, Theme.Spacing.l)
                            .padding(.top, Theme.Spacing.m)
                            .padding(.bottom, Theme.Spacing.s)
                        
                        if profileViewModel.isLoading {
                            LoadingView(useDarkBackground: true)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.xxl)
                        } else if visibleEvents.isEmpty {
                            emptyStateView
                        } else {
                            if selectedSegment == .upcoming {
                                // ZStack layout for upcoming events
                                LazyVStack(spacing: Theme.Spacing.l) {
                                    ForEach(visibleEvents) { event in
                                        NavigationLink(destination: EventDetailView(eventId: event.id, isTalentMapMode: false)) {
                                            NightEventCard(
                                                event: event,
                                                accent: .sioreeIcyBlue,
                                                actionLabel: "Edit Details",
                                                showsFavoriteButton: false
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.l)
                                .padding(.vertical, Theme.Spacing.m)
                            } else {
                                // Minimal vertical list for hosted (past) events.
                                LazyVStack(spacing: Theme.Spacing.s) {
                                    ForEach(visibleEvents) { event in
                                        // Hidden NavigationLink driven by selection so whole row is tappable.
                                        NavigationLink(tag: event, selection: $selectedEventForDetail) {
                                            EventDetailView(eventId: event.id, isTalentMapMode: false)
                                        } label: {
                                            EmptyView()
                                        }
                                        .opacity(0)
                                        .frame(width: 0, height: 0)

                                        HStack(spacing: Theme.Spacing.m) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(event.title)
                                                    .font(.sioreeBody)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.sioreeWhite)
                                                    .lineLimit(1)
                                                Text(HostHomeDateFormatter.event.string(from: event.date))
                                                    .font(.sioreeCaption)
                                                    .foregroundColor(.sioreeLightGrey)
                                            }

                                            Spacer()

                                            // Attendees button: navigates to attendees list
                                            NavigationLink(destination: EventAttendeesView(eventId: event.id, eventName: event.title, isPast: true)) {
                                                HStack(spacing: Theme.Spacing.xs) {
                                                    Image(systemName: "person.2.fill")
                                                        .font(.system(size: 14, weight: .semibold))
                                                    Text("\(event.attendeeCount)")
                                                        .font(.sioreeCaption)
                                                }
                                                .padding(.vertical, Theme.Spacing.xs)
                                                .padding(.horizontal, Theme.Spacing.s)
                                                .background(Color.sioreeLightGrey.opacity(0.06))
                                                .cornerRadius(12)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.vertical, Theme.Spacing.s)
                                        .padding(.horizontal, Theme.Spacing.m)
                                        .background(.ultraThinMaterial.opacity(0.03))
                                        .cornerRadius(Theme.CornerRadius.medium)
                                        .onTapGesture {
                                            // Select to navigate to event detail
                                            selectedEventForDetail = event
                                        }
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.m)
                                .padding(.vertical, Theme.Spacing.m)
                            }
                        }
                    }
                    .padding(.bottom, Theme.Spacing.xl)
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
                .padding(.bottom, 40)
            }
            .sheet(isPresented: $showNewEvent) {
                EventCreateView(onEventCreated: { event in
                    print("📡 HostMyEventsView received event creation callback: \(event.title)")
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
    
    private var customSegmentedControl: some View {
        HStack(spacing: Theme.Spacing.xs) {
            segmentButton(title: "Upcoming", isSelected: selectedSegment == .upcoming) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedSegment = .upcoming
                }
            }
            
            segmentButton(title: "Hosted", isSelected: selectedSegment == .hosted) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedSegment = .hosted
                }
            }
        }
        .padding(4)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    private func segmentButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.sioreeBody)
                .fontWeight(.semibold)
                .foregroundColor(.sioreeWhite)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.s)
                .background(
                    Group {
                        if isSelected {
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.sioreeIcyBlue.opacity(0.9), Color.sioreeIcyBlue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.sioreeIcyBlue.opacity(0.35), radius: 12, x: 0, y: 6)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HostMyEventsView()
        .environmentObject(AuthViewModel())
}

private enum HostHomeDateFormatter {
    static let event: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter
    }()
}

