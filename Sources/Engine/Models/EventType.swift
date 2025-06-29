//
//  EventType.swift
//  Norai
//
//  Created by Amr on 02/06/2025.
//

import Foundation

public enum EventType: String, Codable, CaseIterable, Sendable {
    // E-COMMERCE
    case itemViewed = "item_viewed"
    case itemAddedToCart = "item_added_to_cart"
    case itemPurchased = "item_purchased"
    case itemLiked = "item_liked"
    case itemShared = "item_shared"
    case searchPerformed = "search_performed"
    case filterApplied = "filter_applied"
    
    // CONTENT AND MEDIA
    case contentViewed = "content_viewed"
    case contentSkipped = "content_skipped"
    case contentLiked = "content_liked"
    case contentShared = "content_shared"
    case contentCompleted = "content_completed"
    case scroll = "scroll"
    case pauseResume = "pause_resume"
    
    // USER BEHAVIOR
    case sessionStarted = "session_started"
    case sessionEnded = "session_ended"
    case screenViewed = "screen_viewed"
    case interaction = "interaction"
    case formSubmitted = "form_submitted"
    
    // BEHAVIORAL AND ENGAGEMENT INSIGHTS
    case itemFocusStarted = "item_focus_started"
    case itemFocusEnded = "item_focus_ended"
    case visibleDuration = "visible_duration"
}
