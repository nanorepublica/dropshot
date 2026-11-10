import AppKit

/// Decides whether a drag should pop up the drop panel. The drag pasteboard's
/// change count goes up once per drag, so each drag is judged only once.
struct DragPanelTrigger {
    private(set) var lastChangeCount: Int

    mutating func shouldShow(changeCount: Int, types: [NSPasteboard.PasteboardType]) -> Bool {
        guard changeCount != lastChangeCount else { return false }
        lastChangeCount = changeCount
        return types.contains(.fileURL)
    }
}
