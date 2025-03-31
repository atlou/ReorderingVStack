/*
 MIT License

 Copyright (c) 2025 Xavier Normant

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

//
//  ReorderingVStack.swift
//  ReorderingVStack
//
//  Created by Xavier on 27/03/2025.
//

import SwiftUI

private extension EnvironmentValues {
    @Entry var dragChanged: ((DragGesture.Value) -> Void)? = nil
    @Entry var dragEnded: ((DragGesture.Value) -> Void)? = nil
}

public extension View {
    func dragToReorder(_ isEnabled: Bool = true) -> some View {
        modifier(DragToReorderModifier(isEnabled: isEnabled))
    }
}

private struct DragToReorderModifier: ViewModifier {
    @Environment(\.dragChanged) var dragChanged
    @Environment(\.dragEnded) var dragEnded

    var isEnabled: Bool

    func body(content: Content) -> some View {
        content.gesture(
            DragGesture()
                .onChanged { value in
                    dragChanged?(value)
                }
                .onEnded { value in
                    dragEnded?(value)
                }
        )
        .disabled(!isEnabled)
    }
}

private struct ReorderingRow<Content: View>: View {
    let index: Int
    let content: () -> Content
    let dragChanged: (DragGesture.Value) -> Void
    let dragEnded: (DragGesture.Value) -> Void

    var body: some View {
        content()
            .environment(\.dragChanged, dragChanged)
            .environment(\.dragEnded, dragEnded)
    }
}

public struct ReorderingVStack<Content: View, Item: Identifiable & Hashable>: View {
    @Binding var items: [Item]
    var spacing: CGFloat?

    @ViewBuilder var content: () -> Content

    @State private var dragOffset: CGFloat = 0
    @State private var sourceIndex: Int? = nil
    @State private var draggingItem: Item? = nil
    @State private var currentTarget: Int? = nil
    @State private var rowSizes: [Int: CGSize] = [:]
    @State private var topPositions: [CGFloat] = []

    public init(items: Binding<[Item]>, spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        _items = items
        self.spacing = spacing
        self.content = content
    }

    public var body: some View {
        VStack(spacing: spacing ?? 0) {
            Group(subviews: content()) { collection in
                ForEach(Array(zip(items.indices, items)), id: \.1.id) { (index, item) in
                    let isDragging = (sourceIndex == index)
                    let shift = shiftForRow(at: index)

                    let rowView = ReorderingRow(
                        index: index,
                        content: { collection[index] },
                        dragChanged: { value in
                            handleDragChanged(for: index, value: value)
                        },
                        dragEnded: { _ in
                            handleDragEnded()
                        }
                    )

                    rowView
                        .sizeReader(index, size: sizeBinding(index: index))
                        .opacity(isDragging ? 0 : 1)
                        .offset(y: isDragging ? 0 : shift)
                        .zIndex(isDragging ? 1 : 0)
                        .overlay {
                            if isDragging {
                                rowView
                                    .offset(y: dragOffset)
                            }
                        }
                        .sensoryFeedback(.selection, trigger: currentTarget) { old, new in
                            new != nil && old != nil
                        }
                }
            }
        }
        .onChange(of: rowSizes) {
            print("rowSizes changed")
            self.topPositions = computeTopPositions()
        }
    }

    func sizeBinding(index: Int) -> Binding<CGSize> {
        Binding(
            get: { rowSizes[index] ?? .zero },
            set: { new in
                rowSizes[index] = new
            }
        )
    }

    var rowCenters: [CGFloat] {
        topPositions.enumerated().map { index, top in
            let height = rowSizes[index]?.height ?? 0.0
            return top + height / 2
        }
    }

    // Returns the Y positions (tops) for each row.
    func computeTopPositions() -> [CGFloat] {
        print("computing top pos")
        var positions: [CGFloat] = []
        var current: CGFloat = 0
        for i in 0 ..< items.count {
            // First record the top of row i.
            positions.append(current)

            // Then advance 'current' by the row's height.
            let height = rowSizes[i]?.height ?? 0.0
            current += height

            // If it's not the last row, add spacing.
            if i < items.count - 1 {
                current += spacing ?? 0
            }
        }
        return positions
    }

    // Compute dynamic shift for a row based on drag source and current target.
    func shiftForRow(at index: Int) -> CGFloat {
        guard let source = sourceIndex, let target = currentTarget else {
            return 0
        }
        let rowHeight = (rowSizes[source]?.height ?? 0) + (spacing ?? 0)

        if source < target {
            // Dragging downward
            if index > source && index <= target {
                return -rowHeight
            }
        } else if source > target {
            // Dragging upward
            if index < source && index >= target {
                return rowHeight
            }
        }
        return 0
    }

    func computeTargetIndex(newY: CGFloat, positions _: [CGFloat]) -> Int {
        guard let source = sourceIndex else { return 0 }
        let sourceHeight = rowSizes[source]?.height ?? 0.0
        let draggedCenterY = newY + sourceHeight / 2
        let centers = rowCenters

        // Filter out the source, then find the index with the minimum distance from draggedCenterY.
        return centers.enumerated()
            .min(by: { abs(draggedCenterY - $0.element) < abs(draggedCenterY - $1.element) })?.offset ?? source
    }

    func handleDragChanged(for index: Int, value: DragGesture.Value) {
        if sourceIndex == nil {
            sourceIndex = index
            draggingItem = items[index]
        }

        let rawOffset = value.translation.height
        let originalY = topPositions[sourceIndex!]

        // Clamp the new Y between the top of the first row and the bottom of the last row.
        let minY: CGFloat = topPositions.first ?? 0
        let lastIndex = items.count - 1
        let maxY: CGFloat = topPositions[lastIndex] + (rowSizes[lastIndex]?.height ?? 0.0) - (rowSizes[sourceIndex ?? 0]?.height ?? 0.0)
        let newY = max(min(originalY + rawOffset, maxY), minY)

        withAnimation(.spring(duration: 0.1)) {
            dragOffset = newY - originalY
        }

        let computedTarget = computeTargetIndex(newY: newY, positions: topPositions)
        if computedTarget != currentTarget {
            withAnimation(.spring(duration: 0.15)) {
                currentTarget = computedTarget
            }
        }
    }

    func handleDragEnded() {
        guard let source = sourceIndex, let draggingItem = draggingItem else { return }
        let newIndex = currentTarget ?? source

        // Capture the old positions (current order)
        let oldPositions = topPositions

        // Build a mapping from item to its size using the current order.
        var sizeForItem: [Item: CGSize] = [:]
        for (index, item) in items.enumerated() {
            sizeForItem[item] = rowSizes[index] ?? .zero
        }

        // Create a hypothetical new order: remove the dragged item from its old position and insert it at newIndex.
        var hypotheticalItems = items
        hypotheticalItems.remove(at: source)
        hypotheticalItems.insert(draggingItem, at: newIndex)

        // Compute new top positions based on the hypothetical new order.
        var newPositions: [CGFloat] = []
        var current: CGFloat = 0
        for (i, item) in hypotheticalItems.enumerated() {
            newPositions.append(current)
            let height = sizeForItem[item]?.height ?? 0.0
            current += height
            if i < hypotheticalItems.count - 1 {
                current += spacing ?? 0.0
            }
        }

        // Calculate the final offset:
        // We want the dragged row's top to move from its old position to the target slot in the new layout.
        let finalOffset = newPositions[newIndex] - oldPositions[source]

        // Animate the overlay from its current position to the target position.
        withAnimation(.spring(duration: 0.25)) {
            dragOffset = finalOffset
        } completion: {
            items.remove(at: source)
            items.insert(draggingItem, at: newIndex)
            dragOffset = 0
            sourceIndex = nil
            self.draggingItem = nil
            currentTarget = nil
        }
    }
}
