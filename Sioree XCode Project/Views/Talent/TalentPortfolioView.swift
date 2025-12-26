//
//  TalentPortfolioView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import Combine

struct TalentPortfolioView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var portfolioItems: [PortfolioItem]
    let userId: String
    @State private var showAddEvent = false
    @State private var pastEvents: [Event] = []
    @State private var isLoading = false
    private let networkService = NetworkService()
    @State private var cancellables = Set<AnyCancellable>()
    
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
                
                if portfolioItems.isEmpty {
                    VStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "briefcase.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                        
                        Text("No portfolio items yet")
                            .font(.sioreeH3)
                            .foregroundColor(Color.sioreeWhite)
                        
                        Text("Add events you have helped at to showcase your work")
                            .font(.sioreeBody)
                            .foregroundColor(Color.sioreeLightGrey)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.xl)
                        
                        Button(action: {
                            showAddEvent = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Event")
                                    .font(.sioreeBody)
                            }
                            .foregroundColor(Color.sioreeWhite)
                            .padding(Theme.Spacing.m)
                            .background(Color.sioreeIcyBlue)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        .padding(.top, Theme.Spacing.m)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: Theme.Spacing.m),
                            GridItem(.flexible(), spacing: Theme.Spacing.m)
                        ], spacing: Theme.Spacing.m) {
                            ForEach(portfolioItems) { item in
                                PortfolioCard(item: item)
                            }
                        }
                        .padding(Theme.Spacing.m)
                    }
                }
            }
            .navigationTitle("Portfolio")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddEvent = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.sioreeIcyBlue)
                    }
                }
            }
            .sheet(isPresented: $showAddEvent) {
                AddEventToPortfolioView(
                    portfolioItems: $portfolioItems,
                    pastEvents: pastEvents
                )
            }
            .onAppear {
                loadPastEvents()
            }
        }
    }
    
    private func loadPastEvents() {
        isLoading = true
        // Load past events where talent was booked
        // TODO: Implement backend endpoint to fetch past events for talent
        // For now, we'll use a placeholder
        isLoading = false
    }
}

struct AddEventToPortfolioView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var portfolioItems: [PortfolioItem]
    let pastEvents: [Event]
    @State private var searchText = ""
    @State private var selectedEvent: Event?
    
    var filteredEvents: [Event] {
        if searchText.isEmpty {
            return pastEvents
        }
        return pastEvents.filter { event in
            event.title.localizedCaseInsensitiveContains(searchText) ||
            event.location.localizedCaseInsensitiveContains(searchText)
        }
    }
    
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
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.sioreeLightGrey)
                        
                        TextField("Search events...", text: $searchText)
                            .foregroundColor(.sioreeWhite)
                            .autocapitalization(.none)
                    }
                    .padding(Theme.Spacing.m)
                    .background(Color.sioreeLightGrey.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .stroke(Color.sioreeIcyBlue.opacity(0.3), lineWidth: 1)
                    )
                    .padding(Theme.Spacing.m)
                    
                    if filteredEvents.isEmpty {
                        VStack(spacing: Theme.Spacing.m) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 60))
                                .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
                            
                            Text("No past events found")
                                .font(.sioreeH3)
                                .foregroundColor(Color.sioreeWhite)
                            
                            Text("You need to have worked at events in the past to add them to your portfolio")
                                .font(.sioreeBody)
                                .foregroundColor(Color.sioreeLightGrey)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.Spacing.xl)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Theme.Spacing.m) {
                                ForEach(filteredEvents) { event in
                                    Button(action: {
                                        selectedEvent = event
                                    }) {
                                        HStack {
                                            if let firstImage = event.images.first, !firstImage.isEmpty {
                                                AsyncImage(url: URL(string: firstImage)) { image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                } placeholder: {
                                                    Color.sioreeLightGrey.opacity(0.2)
                                                }
                                                .frame(width: 60, height: 60)
                                                .cornerRadius(Theme.CornerRadius.small)
                                            } else {
                                                Image(systemName: "photo")
                                                    .font(.system(size: 30))
                                                    .foregroundColor(.sioreeIcyBlue)
                                                    .frame(width: 60, height: 60)
                                                    .background(Color.sioreeLightGrey.opacity(0.1))
                                                    .cornerRadius(Theme.CornerRadius.small)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                                Text(event.title)
                                                    .font(.sioreeBody)
                                                    .foregroundColor(.sioreeWhite)
                                                    .lineLimit(1)
                                                
                                                Text(event.location)
                                                    .font(.sioreeCaption)
                                                    .foregroundColor(.sioreeLightGrey)
                                                    .lineLimit(1)
                                                
                                                Text(event.date, style: .date)
                                                    .font(.sioreeCaption)
                                                    .foregroundColor(.sioreeLightGrey)
                                            }
                                            
                                            Spacer()
                                            
                                            if selectedEvent?.id == event.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.sioreeIcyBlue)
                                            }
                                        }
                                        .padding(Theme.Spacing.m)
                                        .background(Color.sioreeLightGrey.opacity(0.1))
                                        .cornerRadius(Theme.CornerRadius.medium)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                                .stroke(selectedEvent?.id == event.id ? Color.sioreeIcyBlue : Color.sioreeIcyBlue.opacity(0.3), lineWidth: selectedEvent?.id == event.id ? 2 : 1)
                                        )
                                    }
                                    .padding(.horizontal, Theme.Spacing.m)
                                }
                            }
                            .padding(.vertical, Theme.Spacing.m)
                        }
                    }
                }
            }
            .navigationTitle("Add Events You Have Helped At")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.sioreeWhite)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if let event = selectedEvent {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "MMM yyyy"
                            let portfolioItem = PortfolioItem(
                                id: event.id,
                                title: event.title,
                                image: event.images.first ?? "",
                                date: dateFormatter.string(from: event.date)
                            )
                            portfolioItems.append(portfolioItem)
                            dismiss()
                        }
                    }
                    .foregroundColor(selectedEvent != nil ? Color.sioreeIcyBlue : Color.sioreeLightGrey)
                    .disabled(selectedEvent == nil)
                }
            }
        }
    }
}

#Preview {
    TalentPortfolioView(portfolioItems: .constant([]), userId: "")
}





















