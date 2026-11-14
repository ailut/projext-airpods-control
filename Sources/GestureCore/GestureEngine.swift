/// A transport-agnostic gesture state machine. It does not decode AirPods packets.
public enum EarbudSide: String, Equatable {
    case left, right
}

public enum GestureTransition: Equatable {
    case began(EarbudSide)
    case ended(EarbudSide)
}

public struct GestureEngine {
    public private(set) var activeSide: EarbudSide?

    public init() {}

    /// Returns true only if a transition changed state. A conflicting hold is ignored.
    @discardableResult
    public mutating func accept(_ transition: GestureTransition) -> Bool {
        switch transition {
        case .began(let side):
            guard activeSide == nil else { return false }
            activeSide = side
            return true
        case .ended(let side):
            guard activeSide == side else { return false }
            activeSide = nil
            return true
        }
    }

    /// Signed volume step while held: left lowers, right raises, idle does nothing.
    public func step() -> Int {
        switch activeSide {
        case .left: return -1
        case .right: return 1
        case .none: return 0
        }
    }
}
