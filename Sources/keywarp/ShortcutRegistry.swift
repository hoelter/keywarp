import Carbon.HIToolbox
import KeywarpCore

/// Registers Shortcuts with RegisterEventHotKey, which needs no Accessibility or
/// Input Monitoring permission, and reports presses by Target bundle identifier.
@MainActor final class ShortcutRegistry {
    private struct Registration {
        let ref: EventHotKeyRef
        let id: UInt32
        var target: String
    }

    private let onPress: @MainActor (String) -> Void
    private var registrations: [Shortcut: Registration] = [:]
    // Starts at 1 so a zeroed EventHotKeyID can never match a Registration.
    private var nextID: UInt32 = 1

    var count: Int { registrations.count }

    init(onPress: @escaping @MainActor (String) -> Void) {
        self.onPress = onPress
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                           EventParamType(typeEventHotKeyID), nil,
                                           MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            guard status == noErr, hotKeyID.signature == ShortcutRegistry.signature else {
                return OSStatus(eventNotHandledErr)
            }
            let registry = Unmanaged<ShortcutRegistry>.fromOpaque(userData!).takeUnretainedValue()
            MainActor.assumeIsolated { registry.pressed(hotKeyID.id) }
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), nil)
        precondition(status == noErr, "InstallEventHandler failed: \(status)")
    }

    /// Makes the registered Shortcuts match `bindings`. A Shortcut that stays bound keeps
    /// its registration and only changes Target, so an unrelated edit never releases it
    /// for another app to take. Returns the Bindings that failed to register.
    func replace(with bindings: [Binding]) -> [(binding: Binding, status: OSStatus)] {
        let wanted = Set(bindings.map(\.shortcut))
        for (shortcut, registration) in registrations where !wanted.contains(shortcut) {
            let status = UnregisterEventHotKey(registration.ref)
            if status != noErr { logger.error("UnregisterEventHotKey failed: \(status)") }
            registrations[shortcut] = nil
        }

        var failures: [(binding: Binding, status: OSStatus)] = []
        for binding in bindings {
            if registrations[binding.shortcut] != nil {
                registrations[binding.shortcut]!.target = binding.target
                continue
            }
            let id = nextID
            nextID += 1
            var ref: EventHotKeyRef?
            // Exclusive, so another exclusive registration of the same Shortcut fails with
            // eventHotKeyExistsErr. Not every conflict is detectable: registering Raycast's ⌘1
            // hotkey succeeds while Raycast holds it.
            let status = RegisterEventHotKey(binding.shortcut.keyCode, Self.carbonModifiers(binding.shortcut.modifiers),
                                             EventHotKeyID(signature: Self.signature, id: id),
                                             GetApplicationEventTarget(), OptionBits(kEventHotKeyExclusive), &ref)
            guard status == noErr, let ref else {
                failures.append((binding, status))
                continue
            }
            registrations[binding.shortcut] = Registration(ref: ref, id: id, target: binding.target)
        }
        return failures
    }

    private func pressed(_ id: UInt32) {
        guard let registration = registrations.values.first(where: { $0.id == id }) else { return }
        onPress(registration.target)
    }

    nonisolated private static let signature: OSType = 0x4B57_5250  // "KWRP"

    private static func carbonModifiers(_ modifiers: Modifiers) -> UInt32 {
        var flags = 0
        if modifiers.contains(.cmd) { flags |= cmdKey }
        if modifiers.contains(.ctrl) { flags |= controlKey }
        if modifiers.contains(.opt) { flags |= optionKey }
        if modifiers.contains(.shift) { flags |= shiftKey }
        return UInt32(flags)
    }
}
