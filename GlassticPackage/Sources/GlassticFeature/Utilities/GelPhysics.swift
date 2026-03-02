import SwiftUI

@MainActor
@Observable
final class GelPhysicsEngine {
    struct Configuration: Sendable {
        var viscosity: CGFloat = 0.7
        var bounciness: CGFloat = 0.6
        var stiffness: CGFloat = 180.0
        var damping: CGFloat = 0.7
        var maxStretch: CGFloat = 100.0
        var wobbleFrequency: CGFloat = 8.0
        var wobbleDecay: CGFloat = 0.92
        
        static let `default` = Configuration()
        
        static let viscousGel = Configuration(
            viscosity: 0.85,
            bounciness: 0.4,
            stiffness: 120.0,
            damping: 0.8
        )
        
        static let bouncyGel = Configuration(
            viscosity: 0.5,
            bounciness: 0.8,
            stiffness: 250.0,
            damping: 0.55
        )
    }
    
    private(set) var offset: CGPoint = .zero
    private(set) var velocity: CGPoint = .zero
    private(set) var wobblePhase: CGFloat = 0
    private(set) var wobbleAmplitude: CGFloat = 0
    private(set) var isDragging: Bool = false
    var restPosition: CGPoint = .zero
    var config: Configuration
    
    private var displayLink: CADisplayLink?
    private var lastUpdateTime: CFTimeInterval = 0
    
    init(config: Configuration = .default) {
        self.config = config
    }
    
    func beginDrag(at point: CGPoint) {
        isDragging = true
        wobbleAmplitude = min(wobbleAmplitude + 0.02, 0.05)
        startSimulation()
    }
    
    func updateDrag(to point: CGPoint, delta: CGPoint) {
        guard isDragging else { return }
        
        let stretch = hypot(point.x - restPosition.x, point.y - restPosition.y)
        let stretchFactor = min(stretch / config.maxStretch, 1.0)
        let resistance = config.viscosity + (1.0 - config.viscosity) * stretchFactor * stretchFactor
        
        let dampedDelta = CGPoint(
            x: delta.x * (1.0 - resistance * 0.8),
            y: delta.y * (1.0 - resistance * 0.8)
        )
        
        var newOffset = CGPoint(
            x: offset.x + dampedDelta.x,
            y: offset.y + dampedDelta.y
        )
        
        if abs(newOffset.x) > config.maxStretch {
            let sign = newOffset.x > 0 ? 1.0 : -1.0
            let excess = abs(newOffset.x) - config.maxStretch
            newOffset.x = sign * (config.maxStretch + log(1 + excess) * 10)
        }
        if abs(newOffset.y) > config.maxStretch {
            let sign = newOffset.y > 0 ? 1.0 : -1.0
            let excess = abs(newOffset.y) - config.maxStretch
            newOffset.y = sign * (config.maxStretch + log(1 + excess) * 10)
        }
        
        velocity = CGPoint(
            x: dampedDelta.x / 0.016,
            y: dampedDelta.y / 0.016
        )
        
        offset = newOffset
        
        let speed = hypot(delta.x, delta.y)
        wobbleAmplitude = min(wobbleAmplitude + speed * 0.001, 0.06)
    }
    
    func endDrag() {
        isDragging = false
        let releaseSpeed = hypot(velocity.x, velocity.y)
        wobbleAmplitude = min(wobbleAmplitude + releaseSpeed * 0.0002, 0.08)
        velocity = CGPoint(
            x: velocity.x * config.bounciness,
            y: velocity.y * config.bounciness
        )
    }
    
    func triggerWobble(intensity: CGFloat = 1.0) {
        wobbleAmplitude = min(wobbleAmplitude + 0.04 * intensity, 0.08)
        startSimulation()
    }
    
    func snapTo(offset newOffset: CGPoint) {
        guard !isDragging else { return }
        
        let impulse = CGPoint(
            x: newOffset.x - offset.x,
            y: newOffset.y - offset.y
        )
        
        offset = newOffset
        velocity = CGPoint(x: impulse.x * 2.0, y: impulse.y * 2.0)
        wobbleAmplitude = min(0.05, wobbleAmplitude + 0.03)
        startSimulation()
    }
    
    func reset() {
        offset = .zero
        velocity = .zero
        wobbleAmplitude = 0
        wobblePhase = 0
        isDragging = false
        stopSimulation()
    }
    
    private func startSimulation() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: SimulationTarget(engine: self), selector: #selector(SimulationTarget.tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
        lastUpdateTime = CACurrentMediaTime()
    }
    
    private func stopSimulation() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    fileprivate func update() {
        let currentTime = CACurrentMediaTime()
        let dt = min(currentTime - lastUpdateTime, 1.0 / 30.0)
        lastUpdateTime = currentTime
        
        wobblePhase += config.wobbleFrequency * dt
        if wobblePhase > .pi * 2 { wobblePhase -= .pi * 2 }
        
        wobbleAmplitude *= pow(config.wobbleDecay, dt * 60)
        if wobbleAmplitude < 0.001 { wobbleAmplitude = 0 }
        
        if isDragging { return }
        
        let displacement = CGPoint(
            x: offset.x - restPosition.x,
            y: offset.y - restPosition.y
        )
        
        let springForce = CGPoint(
            x: -config.stiffness * displacement.x,
            y: -config.stiffness * displacement.y
        )
        
        let dampingForce = CGPoint(
            x: -config.damping * config.stiffness * 2 * velocity.x,
            y: -config.damping * config.stiffness * 2 * velocity.y
        )
        
        let acceleration = CGPoint(
            x: springForce.x + dampingForce.x,
            y: springForce.y + dampingForce.y
        )
        
        velocity = CGPoint(
            x: velocity.x + acceleration.x * dt,
            y: velocity.y + acceleration.y * dt
        )
        
        offset = CGPoint(
            x: offset.x + velocity.x * dt,
            y: offset.y + velocity.y * dt
        )
        
        let speed = hypot(velocity.x, velocity.y)
        let distance = hypot(displacement.x, displacement.y)
        
        if speed < 0.5 && distance < 0.5 && wobbleAmplitude < 0.001 {
            offset = restPosition
            velocity = .zero
            stopSimulation()
        }
    }
}

private class SimulationTarget: @unchecked Sendable {
    weak var engine: GelPhysicsEngine?
    
    init(engine: GelPhysicsEngine) {
        self.engine = engine
    }
    
    @objc func tick() {
        Task { @MainActor [weak self] in
            self?.engine?.update()
        }
    }
}

struct GelDragGesture: Gesture {
    let engine: GelPhysicsEngine
    let onChanged: ((CGPoint) -> Void)?
    let onEnded: (() -> Void)?
    
    init(engine: GelPhysicsEngine, onChanged: ((CGPoint) -> Void)? = nil, onEnded: (() -> Void)? = nil) {
        self.engine = engine
        self.onChanged = onChanged
        self.onEnded = onEnded
    }
    
    var body: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !engine.isDragging {
                    engine.beginDrag(at: value.startLocation)
                }
                engine.updateDrag(
                    to: value.location,
                    delta: CGPoint(
                        x: value.translation.width - engine.offset.x,
                        y: value.translation.height - engine.offset.y
                    )
                )
                onChanged?(engine.offset)
            }
            .onEnded { _ in
                engine.endDrag()
                onEnded?()
            }
    }
}

extension View {
    func gelPhysics(_ engine: GelPhysicsEngine) -> some View {
        self
            .offset(x: engine.offset.x, y: engine.offset.y)
            .scaleEffect(1.0 + engine.wobbleAmplitude * 0.5)
    }
}

@MainActor
@Observable
final class GelSelectionTracker<Item: Hashable & Equatable> {
    private(set) var selectedItem: Item?
    private(set) var previousItem: Item?
    private(set) var animatedPosition: CGFloat = 0
    private(set) var targetPosition: CGFloat = 0
    private var velocity: CGFloat = 0
    private(set) var wobblePhase: CGFloat = 0
    private(set) var wobbleAmplitude: CGFloat = 0
    private var itemFrames: [Item: CGRect] = [:]
    private var containerBounds: CGRect = .zero
    var stiffness: CGFloat = 200
    var damping: CGFloat = 0.7
    
    private var displayLink: CADisplayLink?
    private var lastUpdateTime: CFTimeInterval = 0
    
    init(initialSelection: Item? = nil) {
        self.selectedItem = initialSelection
    }
    
    func updateFrame(_ frame: CGRect, for item: Item, in container: CGRect) {
        itemFrames[item] = frame
        containerBounds = container
        
        if item == selectedItem {
            let center = frame.midX
            let normalizedPos = (center - container.minX) / container.width
            
            if abs(targetPosition - normalizedPos) > 0.001 {
                targetPosition = normalizedPos
                if displayLink == nil { animatedPosition = normalizedPos }
            }
        }
    }
    
    func select(_ item: Item) {
        guard item != selectedItem else { return }
        
        previousItem = selectedItem
        selectedItem = item
        
        if let frame = itemFrames[item] {
            let center = frame.midX
            targetPosition = (center - containerBounds.minX) / containerBounds.width
        }
        
        wobbleAmplitude = 0.04
        startAnimation()
    }
    
    func currentBlobFrame(defaultWidth: CGFloat = 80) -> CGRect {
        guard let selected = selectedItem, let frame = itemFrames[selected] else {
            return CGRect(
                x: animatedPosition * containerBounds.width - defaultWidth / 2,
                y: 0,
                width: defaultWidth,
                height: containerBounds.height
            )
        }
        
        var width = frame.width
        if let previous = previousItem, let prevFrame = itemFrames[previous] {
            let progress = 1.0 - abs(animatedPosition - targetPosition) / abs(targetPosition - (prevFrame.midX - containerBounds.minX) / containerBounds.width + 0.001)
            width = prevFrame.width + (frame.width - prevFrame.width) * min(1, max(0, progress))
        }
        
        let x = animatedPosition * containerBounds.width - width / 2 + containerBounds.minX
        return CGRect(x: x, y: frame.minY, width: width, height: frame.height)
    }
    
    private func startAnimation() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: SelectionAnimationTarget<Item>(tracker: self), selector: #selector(SelectionAnimationTarget<Item>.tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
        lastUpdateTime = CACurrentMediaTime()
    }
    
    private func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    fileprivate func update() {
        let currentTime = CACurrentMediaTime()
        let dt = min(currentTime - lastUpdateTime, 1.0 / 30.0)
        lastUpdateTime = currentTime
        
        wobblePhase += 8.0 * dt
        if wobblePhase > .pi * 2 { wobblePhase -= .pi * 2 }
        wobbleAmplitude *= pow(0.92, dt * 60)
        if wobbleAmplitude < 0.001 { wobbleAmplitude = 0 }
        
        let displacement = animatedPosition - targetPosition
        let springForce = -stiffness * displacement
        let dampingForce = -damping * stiffness * 2 * velocity
        let acceleration = springForce + dampingForce
        
        velocity += acceleration * dt
        animatedPosition += velocity * dt
        
        if abs(velocity) < 0.001 && abs(displacement) < 0.001 && wobbleAmplitude < 0.001 {
            animatedPosition = targetPosition
            velocity = 0
            stopAnimation()
        }
    }
}

private class SelectionAnimationTarget<Item: Hashable & Equatable>: @unchecked Sendable {
    weak var tracker: GelSelectionTracker<Item>?
    
    init(tracker: GelSelectionTracker<Item>) {
        self.tracker = tracker
    }
    
    @objc func tick() {
        Task { @MainActor [weak self] in
            self?.tracker?.update()
        }
    }
}
