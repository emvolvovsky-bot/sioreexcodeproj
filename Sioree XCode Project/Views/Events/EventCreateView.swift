//
//  EventCreateView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import MapKit
import Combine

struct EventCreateView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = EventViewModel(eventId: "")
    var onEventCreated: ((Event) -> Void)? = nil
    var currentUserLocation: String? = nil
    
    @State private var title = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var location = ""
    @State private var showMap = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedAddress: String?
    @State private var ticketPrice: Double?
    @State private var showPriceInput = false
  @State private var capacity: String = ""
    @State private var isPublishing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showStripeSetupPrompt = false
    @State private var stripeSetupMessage = ""
    private let bankService = BankAccountService.shared
    @Environment(\.openURL) private var openURL
    
    @State private var coverPhoto: UIImage?
    @State private var showPhotoPicker = false
    @State private var coverPhotoUrl: String?
    @State private var isUploadingPhoto = false
    
    @State private var selectedTalentIds: [String] = []
    @State private var showTalentBrowser = false
    @StateObject private var photoService = PhotoService.shared
    @State private var cancellables = Set<AnyCancellable>()
    @State private var selectedCategory: EventCategory? = nil
    @State private var selectedSubcategory: String? = nil
    @State private var showCategoryPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGlow
                
                Form {
                    Section {
                        CustomTextField(placeholder: "Event Title", text: $title)
                        CustomTextField(placeholder: "Additional Info", text: $description)
                    } header: {
                        Text("Event Details")
                            .foregroundColor(.sioreeWhite)
                    }
                    
                    Section {
                        Button(action: {
                            showPhotoPicker = true
                        }) {
                            HStack {
                                if let coverPhoto = coverPhoto {
                                    Image(uiImage: coverPhoto)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.sioreeCharcoal.opacity(0.3))
                                            .frame(width: 80, height: 80)
                                        
                                        VStack(spacing: 4) {
                                            Image(systemName: "photo.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.sioreeIcyBlue)
                                            Text("Add Photo")
                                                .font(.caption)
                                                .foregroundColor(.sioreeIcyBlue)
                                        }
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(coverPhoto == nil ? "Required" : "Cover Photo Selected")
                                        .font(.sioreeBody)
                                        .foregroundColor(.sioreeWhite)
                                    Text(coverPhoto == nil ? "Add a cover photo for your event" : "Tap to change")
                                        .font(.caption)
                                        .foregroundColor(.sioreeLightGrey)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.sioreeIcyBlue.opacity(0.7))
                                    .font(.system(size: 14))
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if isUploadingPhoto {
                            HStack {
                                ProgressView()
                                    .tint(.sioreeIcyBlue)
                                Text("Uploading...")
                                    .font(.caption)
                                    .foregroundColor(.sioreeLightGrey)
                            }
                        }
                    } header: {
                        Text("Cover Photo *")
                            .foregroundColor(.sioreeWhite)
                    }
                    
                    Section {
                        Button(action: { showCategoryPicker = true }) {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(.sioreeIcyBlue)
                                Text(selectedSubcategory ?? selectedCategory?.label ?? "Select Category")
                                    .foregroundColor((selectedCategory == nil && selectedSubcategory == nil) ? .sioreeIcyBlue : .sioreeWhite)
                                    .font(.sioreeBody)
                                Spacer()
                                if selectedCategory != nil || selectedSubcategory != nil {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.sioreeIcyBlue)
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.sioreeIcyBlue.opacity(0.7))
                                    .font(.system(size: 14))
                            }
                        }
                        .buttonStyle(.plain)
                    } header: {
                        Text("Category *")
                            .foregroundColor(.sioreeWhite)
                    }
                    
                    Section {
                        DatePicker("Start", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                            .foregroundColor(.sioreeWhite)
                        DatePicker("End", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                            .foregroundColor(.sioreeWhite)
                    } header: {
                        Text("Dates")
                            .foregroundColor(.sioreeWhite)
                    }
                    
                    Section {
                        Button(action: {
                            showMap = true
                        }) {
                            HStack {
                                Image(systemName: "map.fill")
                                    .foregroundColor(.sioreeIcyBlue)
                                Text(selectedAddress ?? "Select Location on Map")
                                    .foregroundColor(selectedAddress == nil ? .sioreeIcyBlue : .sioreeWhite)
                                    .font(.sioreeBody)
                                Spacer()
                                if let coord = selectedCoordinate {
                                    Text("\(coord.latitude, specifier: "%.4f"), \(coord.longitude, specifier: "%.4f")")
                                        .font(.caption)
                                        .foregroundColor(.sioreeLightGrey)
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.sioreeIcyBlue.opacity(0.7))
                                    .font(.system(size: 14))
                            }
                        }
                        .buttonStyle(.plain)
                    } header: {
                        Text("Location")
                            .foregroundColor(.sioreeWhite)
                    }
                    .onChange(of: selectedAddress) { newValue in
                        if let address = newValue, !address.isEmpty {
                            location = address
                        }
                    }
                    
                    Section {
                        Toggle("Ticket Price", isOn: $showPriceInput)
                            .foregroundColor(.sioreeWhite)
                        if showPriceInput {
                            HStack {
                                Text("$")
                                    .foregroundColor(.sioreeWhite)
                                TextField("0.00", value: $ticketPrice, format: .number)
                        .keyboardType(.decimalPad)
                                    .foregroundColor(.sioreeWhite)
                            }
                            .padding(.vertical, Theme.Spacing.m + 2)
                            .padding(.horizontal, Theme.Spacing.m)
                            .background(Color.sioreeCharcoal.opacity(0.7))
                            .cornerRadius(Theme.CornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                    .stroke(Color.sioreeLightGrey.opacity(0.22), lineWidth: 1.2)
                            )
                            
                            // Show estimated net per ticket after Stripe processing fee (2.9% + $0.30)
                            if let price = ticketPrice, price > 0 {
                                let fee = price * 0.029 + 0.30
                                let net = max(price - fee, 0)
                                let netStr = String(format: "%.2f", net)
                                Text("You'll receive $\(netStr) per ticket after Stripe fees")
                                    .font(.caption)
                                    .foregroundColor(.sioreeLightGrey)
                                    .padding(.top, 6)
                            } else {
                                Text("You'll receive $0.00 per ticket after Stripe fees")
                                    .font(.caption)
                                    .foregroundColor(.sioreeLightGrey)
                                    .padding(.top, 6)
                            }
                        }

                        CustomTextField(placeholder: "Capacity (optional)", text: $capacity, keyboardType: .numberPad)
                    } header: {
                        Text("Pricing")
                            .foregroundColor(.sioreeWhite)
                    }

                    Section {
                        Button {
                            showTalentBrowser = true
                        } label: {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.sioreeIcyBlue)
                                Text("Browse & Request Talent")
                                    .foregroundColor(.sioreeIcyBlue)
                                    .font(.sioreeBody)
                                Spacer()
                                if !selectedTalentIds.isEmpty {
                                    Text("\(selectedTalentIds.count)")
                                        .font(.caption)
                                        .foregroundColor(.sioreeIcyBlue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.sioreeIcyBlue.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.sioreeIcyBlue.opacity(0.7))
                                    .font(.system(size: 14))
                            }
                        }
                        .buttonStyle(.plain)

                        Text("Select specific talent to send direct requests to work your event.")
                            .font(.caption)
                            .foregroundColor(.sioreeLightGrey)
                    } header: {
                        Text("Request Talent")
                            .foregroundColor(.sioreeWhite)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeWhite)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        publishEvent()
                    } label: {
                        if isPublishing {
                            ProgressView()
                        } else {
                            Text("Publish")
                                .fontWeight(.semibold)
                                .foregroundColor(canPublish ? .sioreeIcyBlue : .sioreeLightGrey)
                        }
                    }
                    .disabled(!canPublish || isPublishing)
                }
            }
            .fullScreenCover(isPresented: $showMap) {
                EventLocationMapView(selectedLocation: $selectedCoordinate, selectedAddress: $selectedAddress, initialUserLocation: currentUserLocation)
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(selectedImage: $coverPhoto)
            }
            .onChange(of: coverPhoto) { _, newImage in
                if let image = newImage {
                    uploadCoverPhoto(image)
                }
            }
            .fullScreenCover(isPresented: $showTalentBrowser) {
                TalentBrowserView(event: nil, onTalentRequested: { talent in
                    // Add talent ID to selected list if not already there
                    if !selectedTalentIds.contains(talent.userId) {
                        selectedTalentIds.append(talent.userId)
                    }
                    print("Selected talent: \(talent.name) - ID: \(talent.userId)")
                })
            }
            .alert("Event Publish Failed", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage.isEmpty ? "Please try again." : errorMessage)
            }
            .alert("Stripe Setup Required", isPresented: $showStripeSetupPrompt) {
                Button("Complete Stripe Setup") {
                    startStripeOnboarding()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(stripeSetupMessage.isEmpty ? "Complete Stripe setup to publish ticketed events." : stripeSetupMessage)
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryWheelPickerView(selectedCategory: $selectedCategory, selectedSubcategory: $selectedSubcategory)
                    .presentationDetents([.fraction(0.5)])
            }
        }
    }
    
    private var canPublish: Bool {
        !title.isEmpty && 
        !location.isEmpty && 
        coverPhotoUrl != nil &&
        selectedCategory != nil
    }
    
    private func uploadCoverPhoto(_ image: UIImage) {
        isUploadingPhoto = true
        photoService.uploadImage(image)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isUploadingPhoto = false
                    if case .failure(let error) = completion {
                        errorMessage = "Failed to upload cover photo: \(error.localizedDescription)"
                        showError = true
                        coverPhoto = nil
                        coverPhotoUrl = nil
                    }
                },
                receiveValue: { url in
                    isUploadingPhoto = false
                    coverPhotoUrl = url
                    print("✅ Cover photo uploaded: \(url)")
                }
            )
            .store(in: &cancellables)
    }
    
    private func publishEvent() {
        guard canPublish else { return }
        
        isPublishing = true
        let capacityValue = Int(capacity.trimmingCharacters(in: .whitespacesAndNewlines))
        let images = coverPhotoUrl != nil ? [coverPhotoUrl!] : []
        
        viewModel.createEvent(
            title: title,
            description: description,
            date: startDate,
            time: startDate,
            location: location,
            images: images,
            ticketPrice: ticketPrice,
            capacity: capacityValue,
            talentIds: selectedTalentIds,
            lookingForRoles: [],
            lookingForNotes: nil,
            lookingForTalentType: nil
        ) { result in
            DispatchQueue.main.async {
                isPublishing = false
                switch result {
                case .success(let event):
                    onEventCreated?(event)
                    dismiss()
                case .failure(let error):
                    let message = error.localizedDescription
                    if shouldPromptStripeSetup(message) {
                        stripeSetupMessage = "Complete Stripe setup to publish ticketed events."
                        showStripeSetupPrompt = true
                    } else {
                        errorMessage = message
                        showError = true
                    }
                }
            }
        }
    }

    private func shouldPromptStripeSetup(_ message: String) -> Bool {
        message.contains("STRIPE_ONBOARDING_REQUIRED") ||
        message.contains("STRIPE_CONNECT_URLS_NOT_CONFIGURED")
    }

    private func startStripeOnboarding() {
        bankService.createOnboardingLink()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                },
                receiveValue: { url in
                    openURL(url)
                }
            )
            .store(in: &cancellables)
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
    
}


// Category Wheel Picker (half-screen, wheel style with subcategories)
struct CategoryWheelPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCategory: EventCategory?
    @Binding var selectedSubcategory: String?

    // Main categories to choose from
    private let mainCategories: [EventCategory] = [.music, .food, .sport, .movies, .meetups]

    // Subcategory lists
    private let musicSubcategories = [
        "Live Band", "DJ Night", "Silent Disco", "Open Mic", "Karaoke",
        "Listening Party", "Album Release Party", "Jam Session", "Rave",
        "Jazz Night", "Hip Hop Night"
    ]
    private let foodSubcategories = [
        "Dinner Party", "Potluck", "Pizza Party", "Taco Night", "Brunch",
        "Wine Tasting", "Cocktail Party", "Mocktail Night", "Beer Tasting",
        "Food Crawl", "Dessert Night", "Cooking Party"
    ]
    private let moviesSubcategories = [
        "Game Day Watch Party", "Movie Night", "Outdoor Movie Night",
        "TV Finale Watch Party", "Binge Watch Party", "Anime Night",
        "Documentary Screening"
    ]
    private let sportSubcategories = [
        "Sports Watch Party", "Pickup Basketball", "Soccer Game", "Tennis Meetup",
        "Volleyball", "Bowling Night", "Mini Golf", "Hiking Group", "Run Club",
        "Yoga Session", "Ski Meetup", "Snowboard Meetup"
    ]
    private let meetupsSubcategories = [
        "Board Game Night", "Card Game Night", "Poker Night", "Casino Night",
        "Trivia Night", "Murder Mystery", "Escape Room Meetup", "Video Game Night",
        "Mario Kart Tournament", "Esports Watch Party", "House Party", "Theme Party",
        "Costume Party", "Halloween Party", "Glow Party", "Decades Party",
        "Masquerade", "Pajama Party", "Rooftop Party", "Pool Party", "Beach Party",
        "Bonfire", "Networking Mixer", "Social Mixer", "College Party", "Campus Event",
        "Alumni Meetup", "Singles Night", "Speed Dating", "Friend Meetup",
        "Coffee Meetup", "Study Group", "Book Club", "Language Exchange",
        "Paint and Sip", "Craft Night", "DIY Night", "Vision Board Party",
        "Photography Walk", "Writing Circle", "Poetry Night", "Fashion Swap",
        "Wellness Meetup", "Meditation Session", "Sound Bath", "Breathwork Session",
        "Self Care Night", "Pop Up Party", "Secret Location Party", "After Party",
        "Pre Game", "Late Night Meetup", "Surprise Party"
    ]

    @State private var tempCategory: EventCategory = .music
    @State private var tempSubIndex: Int = 0

    private var currentSubcategories: [String] {
        switch tempCategory {
        case .music: return musicSubcategories
        case .food: return foodSubcategories
        case .movies: return moviesSubcategories
        case .sport: return sportSubcategories
        case .meetups: return meetupsSubcategories
        default: return []
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                HStack {
                    Spacer()
                    Text("Select Category")
                        .font(.sioreeH3)
                        .foregroundColor(.sioreeWhite)
                    Spacer()
                }
                Divider().background(Color.sioreeLightGrey.opacity(0.2))

                HStack(spacing: 0) {
                    // Main category wheel
                    Picker("", selection: $tempCategory) {
                        ForEach(mainCategories, id: \.self) { cat in
                            Text(cat.label)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()

                    // Subcategory wheel
                    Picker("", selection: $tempSubIndex) {
                        ForEach(0..<currentSubcategories.count, id: \.self) { idx in
                            Text(currentSubcategories[idx])
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .tag(idx)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
                .frame(height: 220)

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.m)
            .background(
                LinearGradient(
                    colors: [Color.sioreeBlack, Color.sioreeBlack.opacity(0.98), Color.sioreeCharcoal.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.sioreeIcyBlue)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedCategory = tempCategory
                        let subs = currentSubcategories
                        if subs.indices.contains(tempSubIndex) {
                            selectedSubcategory = subs[tempSubIndex]
                        } else {
                            selectedSubcategory = nil
                        }
                        dismiss()
                    }
                    .foregroundColor(.sioreeIcyBlue)
                }
            }
            .onAppear {
                tempCategory = selectedCategory ?? .music
                // set tempSubIndex to index of currently selectedSubcategory if present
                if let sel = selectedSubcategory, let idx = currentSubcategories.firstIndex(of: sel) {
                    tempSubIndex = idx
                } else {
                    tempSubIndex = 0
                }
            }
            .onChange(of: tempCategory) { _ in
                // reset sub index whenever main category changes
                tempSubIndex = 0
            }
        }
    }
}

// Talent Type Picker View
struct TalentTypePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedType: TalentCategory?
    
    var body: some View {
        NavigationStack {
            List {
                Button(action: {
                    selectedType = nil
                    dismiss()
                }) {
                    HStack {
                        Text("None")
                        Spacer()
                        if selectedType == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                ForEach(TalentCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedType = category
                        dismiss()
                    }) {
                        HStack {
                            Text(category.rawValue)
                            Spacer()
                            if selectedType == category {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Talent Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EventCreateView()
}

//trial party

