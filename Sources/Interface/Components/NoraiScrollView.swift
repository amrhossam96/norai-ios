//
//  NoraiScrollView.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import SwiftUI

public struct NoraiScrollView<Data: RandomAccessCollection,
                       ID: Hashable, Content: View>: View where Data.Element: Identifiable,
                                                                Data.Element.ID == ID {

    let data: Data
    let content: (Data.Element) -> Content

    private let screenName: String
    private let componentName: String = "NoraiScrollView"
    
    // State management
    @State private var scrollViewFrame: CGRect = .zero
    @State private var viewFrames: [AnyHashable: ViewFrame] = [:]
    @State private var visibleStartDates: [AnyHashable: Date] = [:]
    @State private var viewProperties: [AnyHashable: [String: String]] = [:]
    
    @State private var lastScrollOffset: CGFloat = 0
    @State private var cachedVisibleArea: CGRect = .zero
    @State private var throttleTask: Task<Void, Never>?
    @State private var currentlyVisible: Set<AnyHashable> = []
    
    private let visibilityThreshold: CGFloat = 0.5
    private let throttleDelay: TimeInterval = 0.016
    private let minimumScrollDelta: CGFloat = 2.0
    private let bufferZone: CGFloat = 100

    public init(
        _ data: Data,
        screenName: String = "UnknownScreen",
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.screenName = screenName
        self.content = content
    }

    public var body: some View {
        GeometryReader { scrollProxy in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(data) { item in
                        content(item)
                            .trackVisibility(id: item.id)
                    }
                }
            }
            .coordinateSpace(name: "noraiScroll")
            .onAppear {
                initializeScrollTracking(frame: scrollProxy.frame(in: .local))
            }
            .onChange(of: scrollProxy.frame(in: .local)) { newFrame in
                handleFrameChange(newFrame: newFrame)
            }
            .onPreferenceChange(TrackingPropertiesPreferenceKey.self) { properties in
                self.viewProperties = properties
            }
        }
        .onPreferenceChange(ViewFramePreferenceKey.self) { frames in
            handleViewFramesChange(frames: frames)
        }
    }
    
    // MARK: - Initialization
    
    @MainActor
    private func initializeScrollTracking(frame: CGRect) {
        self.scrollViewFrame = frame
        self.cachedVisibleArea = createVisibleArea(from: frame)
        scheduleVisibilityComputation()
    }
    
    // MARK: - Frame Change Handling
    
    private func handleFrameChange(newFrame: CGRect) {
        let scrollDelta = abs(newFrame.origin.y - lastScrollOffset)
        
        guard scrollDelta >= minimumScrollDelta else { return }
        
        Task { @MainActor in
            self.scrollViewFrame = newFrame
            self.lastScrollOffset = newFrame.origin.y
            self.cachedVisibleArea = createVisibleArea(from: newFrame)
            scheduleThrottledVisibilityComputation()
        }
    }
    
    private func handleViewFramesChange(frames: [ViewFrame]) {
        let newFrames = Dictionary(uniqueKeysWithValues: frames.map { ($0.id, $0) })
        
        Task { @MainActor in
            self.viewFrames = newFrames
            scheduleThrottledVisibilityComputation()
        }
    }
    
    // MARK: - Optimized Visibility Computation
    
    @MainActor
    private func scheduleVisibilityComputation() {
        computeVisibility()
    }
    
    @MainActor
    private func scheduleThrottledVisibilityComputation() {
        // Cancel previous throttled computation
        throttleTask?.cancel()
        throttleTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(throttleDelay * 1_000_000_000))
            self.computeVisibility()
        }
    }
    
    @MainActor
    private func computeVisibility() {
        guard !cachedVisibleArea.isEmpty else { return }
        
        // Spatial optimization: Create extended viewport for culling
        let extendedViewport = CGRect(
            x: cachedVisibleArea.origin.x,
            y: cachedVisibleArea.origin.y - bufferZone,
            width: cachedVisibleArea.width,
            height: cachedVisibleArea.height + (bufferZone * 2)
        )
        
        var newlyVisible: Set<AnyHashable> = []

        for frameInfo in viewFrames.values {
            let itemFrame = frameInfo.frame
            let id = frameInfo.id
            
            // Early termination: Skip items clearly outside extended viewport
            if itemFrame.maxY < extendedViewport.minY || itemFrame.minY > extendedViewport.maxY {
                handleItemDisappeared(id: id)
                continue
            }
            
            let visibleRatio = calculateVisibilityRatio(
                itemFrame: itemFrame,
                visibleArea: cachedVisibleArea
            )
            
            if visibleRatio > visibilityThreshold {
                newlyVisible.insert(id)
                handleItemAppeared(id: id, ratio: visibleRatio)
            } else {
                handleItemDisappeared(id: id)
            }
        }

        currentlyVisible = newlyVisible
    }
    
    // MARK: - Optimized Calculations
    
    private func createVisibleArea(from frame: CGRect) -> CGRect {
        return CGRect(
            x: 0,
            y: 0,
            width: frame.width,
            height: frame.height
        )
    }
    
    private func calculateVisibilityRatio(itemFrame: CGRect, visibleArea: CGRect) -> CGFloat {
        let intersectionMinX = max(itemFrame.minX, visibleArea.minX)
        let intersectionMinY = max(itemFrame.minY, visibleArea.minY)
        let intersectionMaxX = min(itemFrame.maxX, visibleArea.maxX)
        let intersectionMaxY = min(itemFrame.maxY, visibleArea.maxY)

        guard intersectionMinX < intersectionMaxX && intersectionMinY < intersectionMaxY else {
            return 0
        }
        
        let visibleWidth = intersectionMaxX - intersectionMinX
        let visibleHeight = intersectionMaxY - intersectionMinY
        let visibleArea = visibleWidth * visibleHeight
        
        let totalArea = itemFrame.width * itemFrame.height
        return totalArea > 0 ? visibleArea / totalArea : 0
    }
    
    // MARK: - State Management
    
    private func handleItemAppeared(id: AnyHashable, ratio: CGFloat) {
        if visibleStartDates[id] == nil {
            visibleStartDates[id] = Date()
            sendImpressionEvent(for: id, ratio: ratio, eventName: "item_focus_started")
        }
    }
    
    private func handleItemDisappeared(id: AnyHashable) {
        if let startDate = visibleStartDates[id] {
            let duration = Date().timeIntervalSince(startDate)
            visibleStartDates[id] = nil
            sendImpressionEvent(for: id, ratio: 0, eventName: "item_focus_ended", viewDuration: duration)
        }
    }
    
    // MARK: - Event Tracking
    
    private func sendImpressionEvent(
        for itemId: AnyHashable, 
        ratio: CGFloat, 
        eventName: String,
        viewDuration: TimeInterval? = nil
    ) {
        // Create rich event context
        var context: [String: String] = [:]
        context["screen"] = screenName
        context["component"] = componentName
        context["itemId"] = "\(itemId)"
        if let duration = viewDuration {
            context["viewDuration"] = "\(duration)"
        }
        if let position = findItemPosition(id: itemId) {
            context["position"] = "\(position)"
        }
        context["totalItems"] = "\(data.count)"

        var event = NoraiEvent(
            event: eventName,
            context: context,
            tags: ["impression", "scroll_view", "visibility"]
        )
        event.properties = viewProperties[itemId] ?? [:]
        Norai.shared.track(event: event)
    }
    
    private func findItemPosition(id: AnyHashable) -> Int? {
        return data.firstIndex { $0.id as AnyHashable == id }.map { data.distance(from: data.startIndex, to: $0) }
    }
}
