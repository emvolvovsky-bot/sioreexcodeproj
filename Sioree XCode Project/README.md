# Sioree iOS App - Complete Documentation

## Project Overview

Sioree is a nightlife platform that professionalizes and scales nightlife from the inside out. It connects hosts, partiers, talent, and brands into one seamless ecosystem, streamlining logistics, payments, discovery, and collaboration.

**Platform:** iOS (Latest versions - iOS 17+)  
**Language:** Swift  
**IDE:** Xcode  
**Architecture:** MVVM (Model-View-ViewModel)

---

## Design System

### Color Palette

#### Primary Colors
- **White:** `#FFFFFF` - Primary background, card backgrounds
- **Light Grey:** `#F5F5F5` - Secondary backgrounds, subtle dividers
- **Charcoal:** `#1E1E1E` - Primary text, headers
- **Black:** `#000000` - Deep accents, important text

#### Accent Colors
- **Icy Blue:** `#00D4FF` or `#4FC3F7` - Primary accent, CTAs, highlights
- **Warm Glow:** `#FFB74D` or `#FFA726` - Secondary accent, notifications

#### Semantic Colors
- **Success:** Light green tint
- **Error:** Soft red tint
- **Warning:** Warm yellow tint
- **Info:** Icy blue

### Typography

#### Font Families
- **Primary:** Helvetica Neue (System font fallback)
- **Alternative:** SF Pro Display / SF Pro Text (iOS native)
- **Custom:** Satoshi (if available via custom font)

#### Type Scale
- **H1 (Large Headers):** Bold, 34pt
- **H2 (Section Headers):** Bold, 28pt
- **H3 (Subsection Headers):** Semibold, 22pt
- **H4 (Card Headers):** Semibold, 17pt
- **Body Large:** Regular, 17pt
- **Body:** Regular, 15pt
- **Body Small:** Regular, 13pt
- **Caption:** Regular, 11pt

### Layout & Spacing

#### Spacing System
- **XS:** 4pt
- **S:** 8pt
- **M:** 16pt
- **L:** 24pt
- **XL:** 32pt
- **XXL:** 48pt

#### Border Radius
- **Small:** 4pt (buttons, small cards)
- **Medium:** 8pt (standard cards)
- **Large:** 16pt (large containers)
- **Round:** 50% (avatars, circular elements)

#### Shadows
- **Subtle:** 0 1px 3px rgba(0,0,0,0.05)
- **Medium:** 0 2px 8px rgba(0,0,0,0.08)
- **Elevated:** 0 4px 16px rgba(0,0,0,0.12)

### UI Components

#### Buttons
- **Primary:** Rectangular, full-width or auto-width, icy blue background, white text
- **Secondary:** Rectangular, outlined border, transparent background
- **Tertiary:** Text-only, minimal styling
- **Icon Buttons:** Circular, 44x44pt minimum touch target

#### Cards
- White background, subtle shadow, rounded corners (8pt)
- Padding: 16pt
- Spacing between cards: 16pt

#### Input Fields
- Rectangular, light grey background (#F5F5F5)
- Border: 1pt, light grey
- Focus state: Icy blue border, subtle glow
- Placeholder: Charcoal at 60% opacity

---

## File Structure

```
Sioree/
├── Sioree.xcodeproj/
├── Sioree/
│   ├── App/
│   │   ├── SioreeApp.swift                 # Main app entry point
│   │   ├── AppDelegate.swift               # App lifecycle delegate
│   │   └── SceneDelegate.swift             # Scene lifecycle (if needed)
│   │
│   ├── Models/
│   │   ├── User.swift                      # User model (host, partier, talent, brand)
│   │   ├── Event.swift                     # Event model
│   │   ├── Host.swift                      # Host/Collective model
│   │   ├── Talent.swift                    # Talent/DJ/Worker model
│   │   ├── Booking.swift                   # Booking/Job model
│   │   ├── Post.swift                      # Feed post model
│   │   ├── Badge.swift                     # Profile badge model
│   │   ├── Brand.swift                     # Brand model
│   │   └── Payment.swift                   # Payment transaction model
│   │
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift             # Authentication logic
│   │   ├── FeedViewModel.swift             # Feed/Discovery logic
│   │   ├── ProfileViewModel.swift          # Profile management
│   │   ├── EventViewModel.swift            # Event creation/management
│   │   ├── BookingViewModel.swift          # Booking management
│   │   ├── TalentViewModel.swift           # Talent marketplace
│   │   └── SearchViewModel.swift           # Search functionality
│   │
│   ├── Views/
│   │   ├── Authentication/
│   │   │   ├── LoginView.swift             # Login screen
│   │   │   ├── SignUpView.swift            # Registration screen
│   │   │   └── OnboardingView.swift        # Onboarding flow
│   │   │
│   │   ├── Main/
│   │   │   ├── MainTabView.swift           # Main tab bar container
│   │   │   ├── FeedView.swift              # Main feed/discovery
│   │   │   ├── SearchView.swift            # Search screen
│   │   │   ├── CreateView.swift            # Create event/post
│   │   │   ├── NotificationsView.swift     # Notifications
│   │   │   └── ProfileView.swift           # User profile
│   │   │
│   │   ├── Events/
│   │   │   ├── EventListView.swift         # List of events
│   │   │   ├── EventDetailView.swift       # Event details
│   │   │   ├── EventCreateView.swift       # Create event
│   │   │   └── EventCardView.swift         # Event card component
│   │   │
│   │   ├── Profile/
│   │   │   ├── ProfileHeaderView.swift     # Profile header
│   │   │   ├── ProfileStatsView.swift     # Stats/badges
│   │   │   ├── ProfileEditView.swift      # Edit profile
│   │   │   ├── FollowersView.swift        # Followers list
│   │   │   └── FollowingView.swift        # Following list
│   │   │
│   │   ├── Talent/
│   │   │   ├── TalentMarketplaceView.swift # Talent marketplace
│   │   │   ├── TalentProfileView.swift    # Talent profile
│   │   │   ├── BookingView.swift          # Booking flow
│   │   │   └── TalentCardView.swift       # Talent card component
│   │   │
│   │   ├── Host/
│   │   │   ├── HostDashboardView.swift    # Host dashboard
│   │   │   ├── StaffManagementView.swift  # Manage staff/bookings
│   │   │   └── EventManagementView.swift  # Manage events
│   │   │
│   │   └── Components/
│   │       ├── CustomButton.swift         # Reusable button component
│   │       ├── CustomTextField.swift      # Reusable text field
│   │       ├── EventCard.swift            # Event card component
│   │       ├── TalentCard.swift           # Talent card component
│   │       ├── PostCard.swift             # Feed post card
│   │       ├── BadgeView.swift            # Badge display component
│   │       ├── AvatarView.swift           # Avatar component
│   │       └── LoadingView.swift          # Loading indicator
│   │
│   ├── Services/
│   │   ├── NetworkService.swift           # API networking layer
│   │   ├── AuthService.swift              # Authentication service
│   │   ├── StorageService.swift           # Local storage (UserDefaults/CoreData)
│   │   ├── ImageService.swift             # Image loading/caching
│   │   └── PaymentService.swift           # Payment processing
│   │
│   ├── Utilities/
│   │   ├── Extensions/
│   │   │   ├── Color+Extensions.swift     # Color palette extensions
│   │   │   ├── Font+Extensions.swift      # Typography extensions
│   │   │   ├── View+Extensions.swift      # View modifiers
│   │   │   └── Date+Extensions.swift      # Date formatting
│   │   │
│   │   ├── Constants.swift                # App-wide constants
│   │   ├── Theme.swift                    # Theme/design system
│   │   └── Helpers.swift                  # Utility functions
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets/               # Images, colors, icons
│   │   ├── Fonts/                         # Custom fonts (if any)
│   │   └── Localizable.strings           # Localization strings
│   │
│   └── Info.plist                         # App configuration
│
└── README.md                              # This file
```

---

## Core Functionality

### 1. Authentication & Onboarding

#### LoginView
- **Functionality:**
  - Email/password login
  - Social login (Apple Sign In, Instagram)
  - "Forgot Password" flow
  - Navigation to sign up
- **Styling:**
  - White background
  - Centered logo/branding
  - Minimal input fields with light grey backgrounds
  - Primary button (icy blue) for login
  - Secondary text link for sign up

#### SignUpView
- **Functionality:**
  - User type selection (Host, Partier, Talent, Brand)
  - Email, password, username, profile photo
  - Terms & conditions acceptance
  - Account creation
- **Styling:**
  - Multi-step form with smooth transitions
  - User type selection cards
  - Validation feedback

#### OnboardingView
- **Functionality:**
  - Welcome screens explaining Sioree
  - Feature highlights
  - Permission requests (notifications, location)
- **Styling:**
  - Full-screen slides with minimal text
  - Smooth page transitions
  - Skip/Done buttons

### 2. Main Navigation (Tab Bar)

#### MainTabView
- **Tabs:**
  1. **Feed** - Discovery and events
  2. **Search** - Search events, hosts, talent
  3. **Create** - Create event or post
  4. **Notifications** - Activity feed
  5. **Profile** - User profile
- **Styling:**
  - Custom tab bar with minimal design
  - Icy blue accent for active tab
  - Icon-based navigation

### 3. Feed & Discovery

#### FeedView
- **Functionality:**
  - Scrollable feed of events and posts
  - Filter by: Following, Nearby, Trending, All
  - Pull-to-refresh
  - Infinite scroll
  - Tap event to view details
  - Like, comment, share interactions
- **Styling:**
  - Card-based layout
  - Generous spacing between cards
  - Subtle shadows
  - Smooth scrolling animations

#### EventCardView
- **Functionality:**
  - Display event image, title, host, date/time, location
  - Show attendee count
  - Quick actions: Like, Save, Share
  - Tap to open EventDetailView
- **Styling:**
  - Large hero image (16:9 aspect ratio)
  - Overlay gradient for text readability
  - White text on dark overlay
  - Rounded corners (8pt)

### 4. Event Management

#### EventDetailView
- **Functionality:**
  - Full event information
  - Image gallery
  - Host profile link
  - Talent lineup
  - Ticket purchase/RSVP
  - Share event
  - Report event
- **Styling:**
  - Full-screen hero image
  - Scrollable content below
  - Sticky action bar (RSVP button)
  - Icy blue CTA button

#### EventCreateView
- **Functionality:**
  - Multi-step event creation
  - Basic info (title, description, date, time, location)
  - Image upload (multiple)
  - Ticket pricing
  - Talent/staff booking
  - Publish event
- **Styling:**
  - Form-based layout
  - Step indicator at top
  - Image picker with preview
  - Save as draft option

### 5. Profile System

#### ProfileView
- **Functionality:**
  - User profile header (avatar, name, bio, location)
  - Stats: Events hosted, Events attended, Followers, Following
  - Badges display
  - Tabs: Events, Posts, Saved
  - Edit profile button
  - Follow/Unfollow button
  - Settings button
- **Styling:**
  - Large avatar at top
  - Clean stat cards
  - Badge collection with subtle glow
  - Tab-based content switching

#### ProfileHeaderView
- **Functionality:**
  - Avatar (circular, 100x100pt)
  - Name and username
  - Bio text
  - Location
  - Verification badge (if applicable)
- **Styling:**
  - Centered layout
  - Generous spacing
  - Minimal design

#### BadgeView
- **Functionality:**
  - Display profile badges
  - Examples: "Events Attended 10+", "Verified Host", "Top DJ"
  - Badge tooltip on tap
- **Styling:**
  - Circular or rounded rectangle badges
  - Subtle glow effect (icy blue or warm)
  - Icon + text layout

### 6. Following System

#### FollowersView / FollowingView
- **Functionality:**
  - List of followers/following
  - Search within list
  - Follow/Unfollow actions
  - Tap to view profile
- **Styling:**
  - List layout with avatars
  - Minimal row design
  - Follow button on each row

### 7. Talent Marketplace

#### TalentMarketplaceView
- **Functionality:**
  - Browse talent (DJs, bartenders, staff, etc.)
  - Filter by: Category, Price, Rating, Availability
  - Search talent
  - Sort options
- **Styling:**
  - Grid or list layout
  - Talent cards with image, name, category, price
  - Filter chips at top

#### TalentCardView
- **Functionality:**
  - Display talent profile preview
  - Show: Name, category, rating, price range, availability
  - Quick view button
- **Styling:**
  - Card with talent image
  - Overlay information
  - Rounded corners

#### TalentProfileView
- **Functionality:**
  - Full talent profile
  - Portfolio/work samples
  - Reviews/ratings
  - Booking calendar
  - Book Now button
  - Contact talent
- **Styling:**
  - Similar to ProfileView
  - Booking section highlighted
  - Calendar integration

#### BookingView
- **Functionality:**
  - Select date/time
  - Event details
  - Pricing breakdown
  - Payment method selection
  - Confirm booking
  - Booking confirmation screen
- **Styling:**
  - Multi-step form
  - Clear pricing display
  - Secure payment UI

### 8. Host Dashboard

#### HostDashboardView
- **Functionality:**
  - Overview stats (upcoming events, revenue, bookings)
  - Quick actions: Create Event, Book Talent, Manage Staff
  - Recent activity
  - Revenue analytics
- **Styling:**
  - Dashboard layout with stat cards
  - Chart visualizations (minimal, monochrome)
  - Action buttons

#### StaffManagementView
- **Functionality:**
  - View booked talent/staff
  - Manage bookings
  - Add new bookings
  - Payment status
- **Styling:**
  - List of bookings
  - Status indicators
  - Action buttons per booking

### 9. Search

#### SearchView
- **Functionality:**
  - Search bar
  - Recent searches
  - Trending searches
  - Filter by: Events, Hosts, Talent, Posts
  - Search results with categories
- **Styling:**
  - Clean search interface
  - Category chips
  - Result cards matching feed style

### 10. Notifications

#### NotificationsView
- **Functionality:**
  - Activity feed
  - Filter by: All, Follows, Events, Bookings, Mentions
  - Mark as read
  - Clear all
  - Tap to navigate to relevant content
- **Styling:**
  - List layout
  - Unread indicator (icy blue dot)
  - Avatar + action description
  - Timestamp

### 11. Create/Post

#### CreateView
- **Functionality:**
  - Create event
  - Create post (photo + caption)
  - Share to feed
  - Tag location, hosts, talent
- **Styling:**
  - Image picker
  - Text input area
  - Tag selection UI
  - Publish button

### 12. Components

#### CustomButton
- **Variants:** Primary, Secondary, Tertiary
- **Sizes:** Small, Medium, Large
- **States:** Normal, Disabled, Loading
- **Styling:** Rectangular, rounded corners, proper touch targets

#### CustomTextField
- **Variants:** Standard, Search, Secure
- **States:** Normal, Focused, Error
- **Styling:** Light grey background, rounded corners, focus glow

#### AvatarView
- **Sizes:** Small (40pt), Medium (60pt), Large (100pt)
- **Styling:** Circular, border option, placeholder icon

#### LoadingView
- **Variants:** Spinner, Skeleton, Progress
- **Styling:** Minimal, matches app aesthetic

---

## Technical Implementation

### Architecture: MVVM
- **Models:** Data structures
- **Views:** SwiftUI views (UI layer)
- **ViewModels:** Business logic, state management
- **Services:** Network, storage, external APIs

### Key Services

#### NetworkService
- RESTful API communication
- Request/response handling
- Error handling
- Token management

#### AuthService
- User authentication
- Session management
- Token refresh
- Logout

#### StorageService
- UserDefaults for preferences
- CoreData for offline data (optional)
- Keychain for sensitive data

#### ImageService
- Image loading
- Caching
- Resizing
- Placeholder handling

#### PaymentService
- Payment processing integration
- Transaction management
- Receipt generation

### Data Models

#### User
- id, email, username, name, bio, avatar, userType, location, verified, createdAt

#### Event
- id, title, description, hostId, date, time, location, images, ticketPrice, capacity, attendees, talentIds, status

#### Host
- id, name, bio, avatar, verified, followerCount, eventCount, badges

#### Talent
- id, name, category, bio, avatar, portfolio, rating, priceRange, availability, verified

#### Booking
- id, eventId, talentId, hostId, date, time, status, price, paymentStatus

#### Post
- id, userId, images, caption, likes, comments, createdAt, location

#### Badge
- id, name, description, icon, earnedDate

---

## Color Implementation

All colors will be defined in:
- `Theme.swift` - Swift struct with static color properties
- `Color+Extensions.swift` - SwiftUI Color extensions
- `Assets.xcassets/Colors/` - Asset catalog color definitions

### Usage Example:
```swift
Color.sioreeWhite
Color.sioreeLightGrey
Color.sioreeCharcoal
Color.sioreeBlack
Color.sioreeIcyBlue
Color.sioreeWarmGlow
```

---

## Typography Implementation

Fonts defined in:
- `Font+Extensions.swift` - SwiftUI Font extensions
- `Theme.swift` - Font size constants

### Usage Example:
```swift
.font(.sioreeH1)
.font(.sioreeBody)
.font(.sioreeCaption)
```

---

## State Management

- **@StateObject** for ViewModels
- **@Published** properties in ViewModels
- **@ObservedObject** for view updates
- **@EnvironmentObject** for app-wide state (if needed)

---

## Navigation

- **NavigationStack** (iOS 16+) for navigation
- **TabView** for main tabs
- **Sheet** for modals
- **FullScreenCover** for full-screen presentations

---

## Dependencies (if needed)

- **SwiftUI** - Native UI framework
- **Combine** - Reactive programming
- **URLSession** - Networking
- **CoreData** (optional) - Local storage
- **Keychain** - Secure storage

---

## App Configuration

### Info.plist Requirements
- App display name
- Bundle identifier
- Minimum iOS version (17.0+)
- Privacy descriptions (Camera, Photo Library, Location, Notifications)
- URL schemes (if needed for deep linking)

### Capabilities
- Push Notifications
- Background Modes (if needed)
- Associated Domains (if needed)

---

## Testing Considerations

- Unit tests for ViewModels
- UI tests for critical flows
- Mock services for development
- Test data for previews

---

## Future Enhancements

- Real-time chat/messaging
- Live event updates
- AR/VR integrations
- Advanced analytics
- Social sharing integrations
- Calendar integration
- Map integration for event locations

---

## Development Notes

- All views should support Dark Mode (if enabled in future)
- Accessibility labels required for all interactive elements
- Localization support structure in place
- Error handling for all network calls
- Loading states for async operations
- Empty states for lists/feeds

---

This README serves as the complete blueprint for the Sioree iOS application. All files, functionality, and styling decisions are documented above.

