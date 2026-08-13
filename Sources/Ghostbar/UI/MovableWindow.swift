import AppKit

class MovableWindow: NSPanel {
    private var dragging = false
    private let headerHeight: CGFloat = 38

    // Become the keyboard target so the user can type into the overlay, without
    // making Ghostbar the active application. canBecomeMain stays false (NSPanel
    // default) so App X keeps ownership of the menu bar / frontmost status.
    override var canBecomeKey: Bool { true }

    override func sendEvent(_ event: NSEvent) {
        let h = contentView?.frame.height ?? frame.height
        let inHeader = event.locationInWindow.y >= h - headerHeight
        switch event.type {
        case .leftMouseDown:
            dragging = inHeader
        case .leftMouseUp:
            dragging = false
        case .leftMouseDragged where dragging:
            let o = frame.origin
            setFrameOrigin(NSPoint(x: o.x + event.deltaX, y: o.y - event.deltaY))
            return
        default: break
        }
        super.sendEvent(event)
    }
}
