import Carbon
import Foundation

final class HotKeyManager {
    private var eventHandler: EventHandlerRef?
    private var registeredHotKeys: [EventHotKeyRef] = []
    private var onHotKey: ((Int) -> Void)?

    deinit {
        unregisterHotKeys()

        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    func start(onHotKey: @escaping (Int) -> Void) {
        self.onHotKey = onHotKey

        guard eventHandler == nil else {
            return
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let managerPointer = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else {
                    return noErr
                }

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard status == noErr else {
                    return status
                }

                let manager = Unmanaged<HotKeyManager>
                    .fromOpaque(userData)
                    .takeUnretainedValue()

                manager.handleHotKeyID(hotKeyID.id)
                return noErr
            },
            1,
            &eventType,
            managerPointer,
            &eventHandler
        )
    }

    func registerShortcuts(modifier: HotKeyModifier, count: Int = ShortcutKey.allCases.count) -> [OSStatus] {
        unregisterHotKeys()

        return ShortcutKey.allCases.prefix(count).map { shortcutKey in
            var hotKeyRef: EventHotKeyRef?
            let hotKeyID = EventHotKeyID(signature: Self.signature, id: UInt32(shortcutKey.slot))
            let status = RegisterEventHotKey(
                UInt32(shortcutKey.keyCode),
                modifier.carbonFlags,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )

            if let hotKeyRef, status == noErr {
                registeredHotKeys.append(hotKeyRef)
            }

            return status
        }
    }

    private func unregisterHotKeys() {
        registeredHotKeys.forEach { UnregisterEventHotKey($0) }
        registeredHotKeys.removeAll()
    }

    private func handleHotKeyID(_ id: UInt32) {
        onHotKey?(Int(id))
    }

    private static let signature: OSType = {
        fourCharCode("MSNP")
    }()

    private static func fourCharCode(_ string: String) -> OSType {
        var result: OSType = 0

        for scalar in string.unicodeScalars.prefix(4) {
            result = (result << 8) + OSType(scalar.value)
        }

        return result
    }
}
