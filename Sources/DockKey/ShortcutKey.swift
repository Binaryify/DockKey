import Carbon

enum ShortcutKey: CaseIterable {
    case one
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
    case zero

    var slot: Int {
        switch self {
        case .one:
            return 1
        case .two:
            return 2
        case .three:
            return 3
        case .four:
            return 4
        case .five:
            return 5
        case .six:
            return 6
        case .seven:
            return 7
        case .eight:
            return 8
        case .nine:
            return 9
        case .zero:
            return 10
        }
    }

    var label: String {
        switch self {
        case .zero:
            return "0"
        default:
            return "\(slot)"
        }
    }

    var keyCode: Int {
        switch self {
        case .one:
            return kVK_ANSI_1
        case .two:
            return kVK_ANSI_2
        case .three:
            return kVK_ANSI_3
        case .four:
            return kVK_ANSI_4
        case .five:
            return kVK_ANSI_5
        case .six:
            return kVK_ANSI_6
        case .seven:
            return kVK_ANSI_7
        case .eight:
            return kVK_ANSI_8
        case .nine:
            return kVK_ANSI_9
        case .zero:
            return kVK_ANSI_0
        }
    }
}
