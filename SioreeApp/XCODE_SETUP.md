# Xcode Setup Guide for Sioree

## Prerequisites
- macOS with Xcode 15.0 or later
- iOS 17.0+ deployment target
- Swift 5.9+

## Setup Steps

### 1. Create New Xcode Project
1. Open Xcode
2. Select "File" > "New" > "Project"
3. Choose "iOS" > "App"
4. Configure:
   - Product Name: `Sioree`
   - Team: Your development team
   - Organization Identifier: `com.sioree` (or your identifier)
   - Interface: SwiftUI
   - Language: Swift
   - Storage: None (or Core Data if you want local persistence)
   - Include Tests: Yes (recommended)

### 2. Add Files to Project
1. In Xcode, right-click on the project folder
2. Select "Add Files to Sioree..."
3. Navigate to the `Sioree` folder
4. Select all folders and files
5. Ensure "Copy items if needed" is checked
6. Ensure "Create groups" is selected
7. Click "Add"

### 3. Configure Build Settings
1. Select the project in the navigator
2. Select the "Sioree" target
3. Go to "General" tab:
   - Minimum Deployments: iOS 17.0
   - Supported Destinations: iPhone
4. Go to "Signing & Capabilities":
   - Enable "Automatically manage signing"
   - Select your development team

### 4. Configure Info.plist
- The Info.plist file has been created with all necessary privacy descriptions
- Ensure it's included in the target's "Copy Bundle Resources" build phase

### 5. Add Assets
1. Create an Asset Catalog:
   - Right-click on project > "New File" > "Asset Catalog"
   - Name it "Assets"
2. Add the Logo:
   - Right-click in Assets > "New Image Set"
   - Name it "Logo256x256"
   - Drag `Sioree/Resources/media/Logo256x256.png` into the "Universal" slot
   - Or: Right-click in Assets > "Import..." and select the logo file
3. Add Color Assets:
   - **For each color, create a separate Color Set:**
     1. Right-click in Assets.xcassets > "New Color Set"
     2. Click on the new "Color" item to select it
     3. In the Attributes Inspector (right panel), set the name to match exactly:
        - `sioreeWhite` - Set color to #FFFFFF
        - `sioreeLightGrey` - Set color to #F5F5F5
        - `sioreeCharcoal` - Set color to #1E1E1E
        - `sioreeBlack` - Set color to #000000
        - `sioreeIcyBlue` - Set color to #00D4FF
        - `sioreeWarmGlow` - Set color to #FFB74D
     4. To set the color value:
        - Click the color well in the inspector
        - Switch to "RGB Sliders" tab
        - Enter the hex value or RGB values
        - Make sure "Any Appearance" is selected (or set for both Light/Dark if needed)
   
   **Note:** Each color gets its own Color Set. The name you give it (like `sioreeWhite`) is what you use in code: `Color("sioreeWhite")`
4. Add App Icon (optional):
   - Use the Logo256x256.png as a base
   - Create app icon set in Assets with required sizes

### 6. Update Constants
1. Open `Sioree/Utilities/Constants.swift`
2. Update `Constants.API.baseURL` with your actual API endpoint

### 7. Configure Capabilities (if needed)
1. Select the target
2. Go to "Signing & Capabilities"
3. Add capabilities as needed:
   - Push Notifications
   - Background Modes (if needed)
   - Associated Domains (if needed for deep linking)

### 8. Build and Run
1. Select a simulator or connected device
2. Press Cmd+R to build and run
3. The app should launch with the onboarding flow

### 9. Reopen in Cursor for Live Editing
1. Keep Xcode open with your project
2. Open Cursor (or reopen if already open)
3. In Cursor, go to **File** > **Open Folder**
4. Navigate to and select: `/Users/evolvovsky26/Creative Cloud Files/Mobile App Design/Sioree Main/`
5. Click "Open"
6. Now you can edit Swift files in Cursor and see changes reflected in Xcode:
   - Xcode will automatically detect file changes
   - If a file is open in Xcode, you may see a dialog asking to reload it
   - Press Cmd+Shift+J in Xcode to reveal the file in the navigator if needed
   - Changes are saved immediately and Xcode will pick them up

**Tip:** Keep both Xcode and Cursor open side-by-side for the best development experience. Edit code in Cursor, build and preview in Xcode.

## Project Structure in Xcode

Ensure your project structure matches:

```
Sioree/
├── App/
│   ├── SioreeApp.swift
│   └── ContentView.swift
├── Models/
│   ├── User.swift
│   ├── Event.swift
│   ├── Host.swift
│   ├── Talent.swift
│   ├── Booking.swift
│   ├── Post.swift
│   ├── Badge.swift
│   ├── Brand.swift
│   └── Payment.swift
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── FeedViewModel.swift
│   ├── ProfileViewModel.swift
│   ├── EventViewModel.swift
│   ├── BookingViewModel.swift
│   ├── TalentViewModel.swift
│   └── SearchViewModel.swift
├── Views/
│   ├── Authentication/
│   ├── Main/
│   ├── Events/
│   ├── Profile/
│   ├── Talent/
│   ├── Host/
│   └── Components/
├── Services/
│   ├── NetworkService.swift
│   ├── AuthService.swift
│   ├── StorageService.swift
│   ├── ImageService.swift
│   └── PaymentService.swift
├── Utilities/
│   ├── Extensions/
│   ├── Constants.swift
│   ├── Theme.swift
│   └── Helpers.swift
├── Resources/
│   ├── Assets.xcassets/
│   └── media/
│       └── Logo256x256.png
├── Info.plist
└── README.md
```

## Troubleshooting

### Common Issues

1. **Missing imports**: Ensure all Swift files have proper imports
2. **Network errors**: Update `Constants.API.baseURL` with your backend URL
3. **Color not found**: Add colors to Assets.xcassets or use the Color extension
4. **Preview errors**: Some previews may need mock data - create sample data for testing

## Next Steps

1. Connect to your backend API
2. Implement image upload functionality
3. Add payment processing integration
4. Set up push notifications
5. Add analytics
6. Implement offline support (if needed)

## Testing

1. Create unit tests for ViewModels
2. Create UI tests for critical flows
3. Test on multiple device sizes
4. Test on iOS 17.0+

## Deployment

1. Update version and build numbers
2. Configure App Store Connect
3. Archive the app
4. Upload to App Store Connect
5. Submit for review
