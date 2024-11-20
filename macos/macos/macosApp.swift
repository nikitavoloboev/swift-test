import SwiftData
import SwiftUI

class HotkeyManager {
    private var eventTap: CFMachPort?

    func startListening() {
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (_, _, event, _) -> Unmanaged<CGEvent>? in
                if HotkeyManager.isCommandDotPressed(event) {
                    if let selectedText = getSelectedText() {
                        print("Selected text: \(selectedText)")
                    }
                }
                return Unmanaged.passRetained(event)
            },
            userInfo: nil
        )

        if let eventTap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(
                kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(
                CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }

    static func isCommandDotPressed(_ event: CGEvent) -> Bool {
        let flags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        return flags.contains(.maskCommand) && keyCode == 47
    }
}

func getSelectedText() -> String? {
    guard let frontApp = NSWorkspace.shared.frontmostApplication else {
        print("Failed to get frontmost application.")
        return nil
    }

    guard frontApp.localizedName != nil else {
        print("Failed to get frontmost application's name.")
        return nil
    }

    var selectedText: String?

    if selectedText == nil {
        simulateCommandC()
        selectedText = retrieveCopiedText()
    }

    return selectedText
}

func simulateCommandC() {
    // Simulate pressing Command + C (copy)
    let source = CGEventSource(stateID: .hidSystemState)
    let keyDownEvent = CGEvent(
        keyboardEventSource: source, virtualKey: CGKeyCode(8), keyDown: true)  // Virtual key code for C: 8
    let keyUpEvent = CGEvent(
        keyboardEventSource: source, virtualKey: CGKeyCode(8), keyDown: false)

    keyDownEvent?.flags = .maskCommand
    keyUpEvent?.flags = .maskCommand

    keyDownEvent?.post(tap: .cghidEventTap)
    keyUpEvent?.post(tap: .cghidEventTap)
}

func retrieveCopiedText() -> String? {
    return NSPasteboard.general.string(forType: .string)
}

@main
struct macosApp: App {
    let hotkeyManager = HotkeyManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(
                for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        hotkeyManager.startListening()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
