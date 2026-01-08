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
    @State private var date = Date()
    @State private var time = Date()
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
    
    @State private var coverPhoto: UIImage?
    @State private var showPhotoPicker = false
    @State private var coverPhotoUrl: String?
    @State private var isUploadingPhoto = false
    
    @State private var selectedTalentIds: [String] = []
    @State private var showTalentBrowser = false
    @StateObject private var photoService = PhotoService.shared
    @State private var cancellables = Set<AnyCancellable>()
    
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
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .foregroundColor(.sioreeWhite)
                        DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                            .foregroundColor(.sioreeWhite)
                    } header: {
                        Text("Date & Time")
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
        }
    }
    
    private var canPublish: Bool {
        !title.isEmpty && 
        !location.isEmpty && 
        coverPhotoUrl != nil
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
            date: date,
            time: time,
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
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
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

