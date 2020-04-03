import SwiftMatrixSDK

protocol MessageViewModelProtocol {
    var id: String { get }
    var text: String { get }
    var sender: String { get }
    var showSender: Bool { get }
    var timestamp: String { get }
    var reactions: [String] { get }
}

extension MessageViewModelProtocol {
    var isEmoji: Bool {
        (text.count <= 3) && text.containsOnlyEmoji
    }

    var groupedReactions: [(String, Int)] {
        reactions
            .reduce(into: [:]) { counts, reaction in counts[reaction, default: 0] += 1 }
            .sorted { $0.1 > $1.1 }
    }
}

struct MessageViewModel: MessageViewModelProtocol {
    enum Error: Swift.Error {
        case invalidEventType(MXEventType)

        var localizedDescription: String {
            switch self {
            case .invalidEventType(let type):
                return "Expected message event, found \(type)"
            }
        }
    }

    var id: String {
        event.eventId
    }

    var text: String {
        return (event.content["body"] as? String).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        } ?? "Error: expected string body"
    }

    var sender: String {
        event.sender
    }

    var showSender: Bool

    var timestamp: String {
        Formatter.string(for: event.timestamp, timeStyle: .short)
    }

    var reactions: [String]

    private let event: MXEvent

    public init(event: MXEvent, reactions: [String], showSender: Bool) throws {
        try Self.validate(event: event)

        self.event = event
        self.showSender = showSender
        self.reactions = reactions
    }

    private static func validate(event: MXEvent) throws {
        let eventType = MXEventType(identifier: event.type)
        // FIXME: Replace with simple `eventType == .roomMessage`
        // once https://github.com/matrix-org/matrix-ios-sdk/pull/755 is part of a release (presumably v0.15.3):

        guard case .roomMessage = eventType else {
            throw Error.invalidEventType(eventType)
        }
    }
}
