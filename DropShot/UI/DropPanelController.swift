import AppKit

/// A large "Send to mini" drop target that appears at the top centre of the
/// screen while any file is being dragged, and hides when the drag ends.
final class DropPanelController {

    private static let size = NSSize(width: 480, height: 120)
    private static let pollInterval: TimeInterval = 0.15

    private let onFilesDropped: ([URL]) -> Void
    private let dragPasteboard = NSPasteboard(name: .drag)
    private var trigger: DragPanelTrigger
    private var panel: NSPanel?
    private var label: NSTextField?
    private var background: NSVisualEffectView?
    private var timer: Timer?

    init(onFilesDropped: @escaping ([URL]) -> Void) {
        self.onFilesDropped = onFilesDropped
        self.trigger = DragPanelTrigger(lastChangeCount: dragPasteboard.changeCount)
    }

    // MARK: - Drag watching

    // Polling, because other apps' drag sessions don't reach event monitors.
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    private func poll() {
        let mouseDown = NSEvent.pressedMouseButtons & 1 != 0
        let types = dragPasteboard.types ?? []

        if mouseDown, trigger.shouldShow(changeCount: dragPasteboard.changeCount, types: types) {
            show()
        } else if !mouseDown, panel?.isVisible == true {
            hide()
        }
    }

    // MARK: - Panel

    private func show() {
        let panel = self.panel ?? makePanel()
        self.panel = panel
        setHighlighted(false)

        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        if let visible = screen?.visibleFrame {
            let origin = NSPoint(
                x: visible.midX - Self.size.width / 2,
                y: visible.maxY - Self.size.height - 12
            )
            panel.setFrameOrigin(origin)
        }
        panel.orderFrontRegardless()
    }

    private func hide() {
        panel?.orderOut(nil)
    }

    private func setHighlighted(_ highlighted: Bool) {
        label?.stringValue = highlighted ? "Drop to send" : "Send to mini"
        background?.material = highlighted ? .selection : .hudWindow
    }

    private func makePanel() -> NSPanel {
        let frame = NSRect(origin: .zero, size: Self.size)
        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false

        let background = NSVisualEffectView(frame: frame)
        background.material = .hudWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 18
        background.layer?.masksToBounds = true

        let label = NSTextField(labelWithString: "Send to mini")
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.alignment = .center
        label.frame = NSRect(x: 0, y: (frame.height - 30) / 2, width: frame.width, height: 30)
        background.addSubview(label)

        let dropView = DragDestinationView(frame: frame)
        dropView.autoresizingMask = [.width, .height]
        dropView.onDragEntered = { [weak self] in self?.setHighlighted(true) }
        dropView.onDragExited = { [weak self] in self?.setHighlighted(false) }
        dropView.onFilesDropped = { [weak self] urls in
            self?.hide()
            self?.onFilesDropped(urls)
        }
        background.addSubview(dropView)

        panel.contentView = background
        self.label = label
        self.background = background
        return panel
    }
}
