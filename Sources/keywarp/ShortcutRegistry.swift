import Carbon.HIToolbox
import KeywarpCore

/// Registers Shortcuts with RegisterEventHotKey, which needs no Accessibility or
/// Input Monitoring permission, and reports presses by Target bundle identifier.
@MainActor final class ShortcutRegistry {
    private let onPress: @MainActor (String) -> Void
    private var registered: [EventHotKeyRef] = []
    private var targets: [UInt32: String] = [:]

    var count: Int { registered.count }

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

    /// Replaces every registered Shortcut. Returns the Bindings that failed to
    /// register, typically because another app already holds the Shortcut.
    func replace(with bindings: [Binding]) -> [(binding: Binding, status: OSStatus)] {
        for ref in registered {
            let status = UnregisterEventHotKey(ref)
            if status != noErr { logger.error("UnregisterEventHotKey failed: \(status)") }
        }
        registered = []
        targets = [:]
        var failures: [(binding: Binding, status: OSStatus)] = []
        // IDs start at 1 so a zeroed EventHotKeyID can never match a Binding.
        for (id, binding) in zip(UInt32(1)..., bindings) {
            var ref: EventHotKeyRef?
            // Exclusive, so a Shortcut another app already holds fails loudly instead of being shared.
            let status = RegisterEventHotKey(binding.shortcut.keyCode, Self.carbonModifiers(binding.shortcut.modifiers),
                                             EventHotKeyID(signature: Self.signature, id: id),
                                             GetApplicationEventTarget(), OptionBits(kEventHotKeyExclusive), &ref)
            guard status == noErr, let ref else {
                failures.append((binding, status))
                continue
            }
            registered.append(ref)
            targets[id] = binding.target
        }
        return failures
    }

    private func pressed(_ id: UInt32) {
        guard let target = targets[id] else { return }
        onPress(target)
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
