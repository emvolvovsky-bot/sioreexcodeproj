# Brand Promotion System

## Overview
Brands can promote events to make them appear in the "Featured" section for partiers. When a brand promotes an event, it becomes featured and appears at the top of the partier home feed.

## How It Works

### Backend
1. **Database Table**: `event_promotions` table stores which brands are promoting which events
2. **Endpoints**:
   - `POST /api/events/:id/promote` - Brand promotes an event
   - `DELETE /api/events/:id/promote` - Brand removes promotion
   - `GET /api/events/featured` - Get all featured events (promoted by brands)

### Frontend
1. **Partier Home View**: Shows two sections:
   - **Featured** (horizontal scroll) - Events promoted by brands
   - **Near You** (horizontal scroll) - Regular nearby events

2. **Brand Promotion**: Brands can call `NetworkService.promoteEvent()` to promote events

## Usage

### For Brands to Promote an Event:
```swift
let networkService = NetworkService()
networkService.promoteEvent(
    eventId: "event-123",
    expiresAt: Date().addingTimeInterval(7 * 24 * 60 * 60), // 7 days from now
    promotionBudget: 100.0 // Optional budget
)
```

### For Brands to Remove Promotion:
```swift
networkService.unpromoteEvent(eventId: "event-123")
```

## Database Schema
- `event_promotions` table links events to brands
- Events with active promotions have `is_featured = true`
- Promotions can have expiration dates
- Multiple brands can promote the same event

## Features
- ✅ Events promoted by brands appear in "Featured" section
- ✅ Horizontal scrolling for both Featured and Near You sections
- ✅ Real-time promotion system
- ✅ Expiration dates for promotions
- ✅ Budget tracking (for future payment integration)

