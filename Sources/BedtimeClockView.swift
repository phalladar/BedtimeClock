//
//  BedtimeClockView.swift
//  BedtimeClockView
//
//  Created by Leonardo Cardoso on 27/03/2017.
//  Copyright © 2017 leocardz.com. All rights reserved.
//

import UIKit

@objc(BedtimeClockViewResizingBehavior)
public enum ResizingBehavior: Int {

    case aspectFit /// The content is proportionally resized to fit into the target rectangle.
    case aspectFill /// The content is proportionally resized to completely fill the target rectangle.
    case stretch /// The content is stretched to match the entire target rectangle.
    case center /// The content is centered in the target rectangle, but it is NOT resized.

    public func apply(rect: CGRect, target: CGRect) -> CGRect {

        if rect == target || target == CGRect.zero { return rect }

        var scales = CGSize.zero
        scales.width = abs(target.width / rect.width)
        scales.height = abs(target.height / rect.height)

        switch self {
        case .aspectFit:

            scales.width = min(scales.width, scales.height)
            scales.height = scales.width

        case .aspectFill:

            scales.width = max(scales.width, scales.height)
            scales.height = scales.width

        case .stretch:

            break

        case .center:

            scales.width = 1
            scales.height = 1

        }

        var result = rect.standardized
        result.size.width *= scales.width
        result.size.height *= scales.height
        result.origin.x = target.minX + (target.width - result.width) / 2
        result.origin.y = target.minY + (target.height - result.height) / 2

        return result

    }
}

public class BedtimeClockView: UIView {

    // MARK: - Position properties
    private let pointersY: CGFloat = 50
    private let pointers2Y: CGFloat = -54
    private let pointers3Y: CGFloat = 51
    private let pointers4Y: CGFloat = -55
    private let pointer6Y: CGFloat = 51
    private let pointer12Y: CGFloat = -54
    private let rotation: CGFloat = 0

    // MARK: - Position variable properties
    var dayRotation: CGFloat = 90 { didSet { self.drawActivity() } }
    var nightRotation: CGFloat = 0 { didSet { self.drawActivity() } }

    // MARK: - Layout properties
    private let hourPointerWidth: CGFloat = 1
    private let hourPointerHeight: CGFloat = 3
    private let minutePointerWidth: CGFloat = 0.5

    // MARK: - Color properties
    private let offsideWatch: UIColor = UIColor(red: 0.087, green: 0.088, blue: 0.087, alpha: 1.000)
    private let centerBackground: UIColor = UIColor(red: 0.049, green: 0.049, blue: 0.049, alpha: 1.000)
    private let circleEndOriginal: UIColor = UIColor(red: 0.976, green: 0.645, blue: 0.068, alpha: 1.000)
    private let thickPointer: UIColor = UIColor(red: 0.557, green: 0.554, blue: 0.576, alpha: 1.000)
    private let thinPointer: UIColor = UIColor(red: 0.329, green: 0.329, blue: 0.329, alpha: 1.000)

    // MARK: - Fixed properties
    private var angle: CGFloat { return -720 * self.rotation }

    private var dayRotationModulus: CGFloat { return fmod(self.dayRotation, 720) }
    private var nightRotationModulus: CGFloat { return fmod(self.nightRotation, 720) }

    private var trackEndAngle: CGFloat { return abs(self.dayRotationModulus + 542) }
    private var trackStartAngle: CGFloat { return self.equalPositionInCircle ? self.nightRotationModulus + 359 : self.nightRotationModulus + 0.01 }

    private var startPosition: CGFloat { return fmod((720 - fmod((180 + self.dayRotationModulus), 720)), 720) }
    private var endPosition: CGFloat { return fmod((720 - self.nightRotationModulus), 720) }

    private var startPositionHour: CGFloat { return floor(self.startPosition / 30.0) }
    private var endPositionHour: CGFloat { return floor(self.endPosition / 30.0) }

    private var startPositionMinute: CGFloat { return floor(fmod(floor(self.startPosition), 30) * 2 / 5.0) * 5 }
    private var endPositionMinute: CGFloat { return ceil(fmod(floor(self.endPosition), 30) * 2 / 5.0) * 5 }

    private var startInMinutes: CGFloat { return self.startPositionHour * 60 + self.startPositionMinute }
    private var endInMinutes: CGFloat { return self.endPositionHour * 60 + self.endPositionMinute }

    private var dayFrameAngle: CGFloat { return self.dayRotation - 25 }
    private var nightFrameAngle: CGFloat { return self.nightRotation + 210 }

    private var dayIconAngle: CGFloat { return -(self.dayRotation + 64.5) }
    private var nightIconAngle: CGFloat { return -(self.nightRotation + 220) }

    private var difference: CGFloat { return self.endInMinutes > self.startInMinutes ? 1440 - self.endInMinutes + self.startInMinutes : abs(self.endInMinutes - self.startInMinutes) }

    private var minuteDifference: CGFloat { return fmod(self.difference, 60) }
    private var hourDifference: CGFloat { return self.startPosition == self.endPosition ? 0 : floor(fmod(self.difference / 60.0, 60)) }
    private var timeDifference: String { return (self.hourDifference > 0 ? "\(Int(round(self.hourDifference)))" + "h " : (self.minuteDifference > 0 ? "" : "24h")) + (self.minuteDifference > 0 ? "\(Int(round(self.minuteDifference)))" + "min" : "") }

    private var equalPositionInCircle: Bool { return fmod(self.startPosition, 30) == fmod(self.endPosition, 30) + 2 }

    // MARK: - Properties
    var context: CGContext?
    var targetFrame: CGRect = .zero

    init(frame: CGRect, startHour: TimeInterval, endHour: TimeInterval) {

        super.init(frame: frame)

        self.targetFrame = frame

        // TODO: Convet startHour and endHour to dayRotation Position
        // TODO: fatalError if the hours are < 0 and > number of miliseconds in a day

    }

    required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func draw(_ rect: CGRect) {

        self.drawActivity()

    }

    // Drawing Methods
    public func drawActivity(resizing: ResizingBehavior = .aspectFit) {

        // General Declarations
        if self.context == nil { self.context = UIGraphicsGetCurrentContext() }

        if let context: CGContext = self.context {

            // Resize to target frame
            context.saveGState()
            let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 156, height: 195), target: targetFrame)
            context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
            context.scaleBy(x: resizedFrame.width / 156, y: resizedFrame.height / 195)

            self.drawForms()

            self.restoreState(times: 2)

            self.drawWakePoint()

            self.restoreState()

            self.drawBellPath()

            self.restoreState(times: 2)

            self.drawSleepPoint()

            self.drawStarsPath()

            self.drawMoonPath()

            self.restoreState(times: 4)

            self.drawHourPointers()

            self.restoreState(times: 3)

            self.drawMinutePointers()

            self.restoreState(times: 3)

            // Numbers
            context.saveGState()
            context.translateBy(x: 78, y: 97)
            context.rotate(by: -360 * CGFloat.pi/180)

            self.drawNumbers(text: "12", position: CGPoint(x: -5, y: -47.5))

            self.restoreState()

            self.drawNumbers(text: "2", position: CGPoint(x: 34, y: -26))

            self.restoreState()

            self.drawNumbers(text: "3", position: CGPoint(x: 40, y: -5))

            self.restoreState()

            self.drawNumbers(text: "4", position: CGPoint(x: 34, y: 16))

            self.restoreState()

            self.drawNumbers(text: "5", position: CGPoint(x: 18, y: 32))

            self.restoreState()

            self.drawNumbers(text: "6", position: CGPoint(x: -5, y: 39))

            self.restoreState()

            self.drawNumbers(text: "7", position: CGPoint(x: -26, y: 32))

            self.restoreState()

            self.drawNumbers(text: "8", position: CGPoint(x: -43, y: 16))

            self.restoreState()

            self.drawNumbers(text: "9", position: CGPoint(x: -50, y: -5))

            self.restoreState()

            self.drawNumbers(text: "10", position: CGPoint(x: -42, y: -26))

            self.restoreState()

            self.drawNumbers(text: "1", position: CGPoint(x: 16, y: -43))

            self.restoreState()

            self.drawNumbers(text: "11", position: CGPoint(x: -24, y: -43))

            self.restoreState(times: 2)

            // Duration Drawing
            let durationRect: CGRect = CGRect(x: 44, y: 82, width: 69, height: 30)
            let durationStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
            durationStyle.alignment = .center

            let durationFontAttributes: [String : Any] = [NSFontAttributeName: UIFont.systemFont(ofSize: UIFont.smallSystemFontSize, weight: UIFontWeightLight), NSForegroundColorAttributeName: UIColor.white, NSParagraphStyleAttributeName: durationStyle]

            let durationTextHeight: CGFloat = timeDifference.boundingRect(with: CGSize(width: durationRect.width, height: CGFloat.infinity), options: .usesLineFragmentOrigin, attributes: durationFontAttributes, context: nil).height

            context.saveGState()
            context.clip(to: durationRect)

            self.timeDifference.draw(in: CGRect(x: durationRect.minX, y: durationRect.minY + (durationRect.height - durationTextHeight) / 2, width: durationRect.width, height: durationTextHeight), withAttributes: durationFontAttributes)

            self.restoreState(times: 2)

        }

    }

    func drawNumbers(text: String, position: CGPoint) {

        let rect = CGRect(x: position.x, y: position.y, width: 10, height: 10)

        let style: NSMutableParagraphStyle = NSMutableParagraphStyle()
        style.alignment = .center
        
        let fontAttributes: [String : Any] = [NSFontAttributeName: UIFont.systemFont(ofSize: 8), NSForegroundColorAttributeName: thickPointer, NSParagraphStyleAttributeName: style]

        let height: CGFloat = text.boundingRect(with: CGSize(width: rect.width, height: CGFloat.infinity), options: .usesLineFragmentOrigin, attributes: fontAttributes, context: nil).height

        self.context?.saveGState()
        self.context?.clip(to: rect)

        text.draw(in: CGRect(x: rect.minX, y: rect.minY + (rect.height - height) / 2, width: rect.width, height: height), withAttributes: fontAttributes)

    }

    // MARK: - Functions
    func updatePositions() {

    }

    // MARK: - Drawing functions
    func drawForms() {

        // BackgroundsGroup
        self.context?.saveGState()
        self.context?.translateBy(x: 78, y: 97)
        self.context?.rotate(by: -90 * CGFloat.pi/180)

        // OffsetBackground drawing
        let offsetBackgroundPath = UIBezierPath(ovalIn: CGRect(x: -74, y: -74, width: 148, height: 148))
        self.offsideWatch.setFill()
        offsetBackgroundPath.fill()

        // TimeBackground drawing
        let timeBackgroundPath = UIBezierPath(ovalIn: CGRect(x: -55, y: -55, width: 110, height: 110))
        self.centerBackground.setFill()
        timeBackgroundPath.fill()
        self.centerBackground.setStroke()
        timeBackgroundPath.lineWidth = 1.5
        timeBackgroundPath.stroke()

        // TrackBackground drawing
        self.context?.saveGState()
        self.context?.rotate(by: -angle * CGFloat.pi/180)

        let trackBackgroundRect = CGRect(x: -65, y: -65, width: 130, height: 130)
        let trackBackgroundPath = UIBezierPath()
        trackBackgroundPath.addArc(
            withCenter: CGPoint(x: trackBackgroundRect.midX, y: trackBackgroundRect.midY),
            radius: trackBackgroundRect.width / 2,
            startAngle: -trackStartAngle * CGFloat.pi/180,
            endAngle: -trackEndAngle * CGFloat.pi/180,
            clockwise: true
        )

        self.circleEndOriginal.setStroke()
        trackBackgroundPath.lineWidth = 18.5
        trackBackgroundPath.lineCapStyle = .round
        trackBackgroundPath.stroke()

    }

    func drawStarsPath() {

        let starsPath: UIBezierPath = UIBezierPath()
        starsPath.move(to: CGPoint(x: 2.19, y: -3.11))
        starsPath.addCurve(to: CGPoint(x: 1.6, y: -3.7), controlPoint1: CGPoint(x: 2.09, y: -3.35), controlPoint2: CGPoint(x: 1.83, y: -3.61))
        starsPath.addLine(to: CGPoint(x: 1.29, y: -3.82))
        starsPath.addLine(to: CGPoint(x: 1.6, y: -3.95))
        starsPath.addCurve(to: CGPoint(x: 2.19, y: -4.53), controlPoint1: CGPoint(x: 1.83, y: -4.04), controlPoint2: CGPoint(x: 2.09, y: -4.3))
        starsPath.addLine(to: CGPoint(x: 2.31, y: -4.85))
        starsPath.addLine(to: CGPoint(x: 2.43, y: -4.53))
        starsPath.addCurve(to: CGPoint(x: 3.02, y: -3.95), controlPoint1: CGPoint(x: 2.52, y: -4.3), controlPoint2: CGPoint(x: 2.78, y: -4.04))
        starsPath.addLine(to: CGPoint(x: 3.33, y: -3.82))
        starsPath.addLine(to: CGPoint(x: 3.02, y: -3.7))
        starsPath.addCurve(to: CGPoint(x: 2.43, y: -3.11), controlPoint1: CGPoint(x: 2.78, y: -3.61), controlPoint2: CGPoint(x: 2.52, y: -3.35))
        starsPath.addLine(to: CGPoint(x: 2.31, y: -2.8))
        starsPath.addLine(to: CGPoint(x: 2.19, y: -3.11))
        starsPath.close()
        starsPath.move(to: CGPoint(x: 3.28, y: -1.27))
        starsPath.addCurve(to: CGPoint(x: 2.92, y: -1.64), controlPoint1: CGPoint(x: 3.23, y: -1.42), controlPoint2: CGPoint(x: 3.07, y: -1.58))
        starsPath.addLine(to: CGPoint(x: 2.9, y: -1.65))
        starsPath.addLine(to: CGPoint(x: 2.92, y: -1.66))
        starsPath.addCurve(to: CGPoint(x: 3.28, y: -2.02), controlPoint1: CGPoint(x: 3.06, y: -1.71), controlPoint2: CGPoint(x: 3.23, y: -1.88))
        starsPath.addLine(to: CGPoint(x: 3.29, y: -2.04))
        starsPath.addLine(to: CGPoint(x: 3.3, y: -2.02))
        starsPath.addCurve(to: CGPoint(x: 3.67, y: -1.66), controlPoint1: CGPoint(x: 3.36, y: -1.88), controlPoint2: CGPoint(x: 3.52, y: -1.71))
        starsPath.addLine(to: CGPoint(x: 3.69, y: -1.65))
        starsPath.addLine(to: CGPoint(x: 3.67, y: -1.64))
        starsPath.addCurve(to: CGPoint(x: 3.3, y: -1.27), controlPoint1: CGPoint(x: 3.52, y: -1.58), controlPoint2: CGPoint(x: 3.36, y: -1.42))
        starsPath.addLine(to: CGPoint(x: 3.29, y: -1.25))
        starsPath.addLine(to: CGPoint(x: 3.28, y: -1.27))
        starsPath.close()
        starsPath.move(to: CGPoint(x: 1.3, y: -0.14))
        starsPath.addCurve(to: CGPoint(x: 0.93, y: -0.5), controlPoint1: CGPoint(x: 1.24, y: -0.28), controlPoint2: CGPoint(x: 1.08, y: -0.45))
        starsPath.addLine(to: CGPoint(x: 0.91, y: -0.51))
        starsPath.addLine(to: CGPoint(x: 0.93, y: -0.52))
        starsPath.addCurve(to: CGPoint(x: 1.3, y: -0.89), controlPoint1: CGPoint(x: 1.08, y: -0.58), controlPoint2: CGPoint(x: 1.24, y: -0.74))
        starsPath.addLine(to: CGPoint(x: 1.31, y: -0.91))
        starsPath.addLine(to: CGPoint(x: 1.32, y: -0.89))
        starsPath.addCurve(to: CGPoint(x: 1.68, y: -0.52), controlPoint1: CGPoint(x: 1.37, y: -0.74), controlPoint2: CGPoint(x: 1.53, y: -0.58))
        starsPath.addLine(to: CGPoint(x: 1.7, y: -0.51))
        starsPath.addLine(to: CGPoint(x: 1.68, y: -0.5))
        starsPath.addCurve(to: CGPoint(x: 1.32, y: -0.14), controlPoint1: CGPoint(x: 1.54, y: -0.45), controlPoint2: CGPoint(x: 1.37, y: -0.29))
        starsPath.addLine(to: CGPoint(x: 1.31, y: -0.12))
        starsPath.addLine(to: CGPoint(x: 1.3, y: -0.14))
        starsPath.close()
        starsPath.usesEvenOddFillRule = true
        self.circleEndOriginal.setFill()
        starsPath.fill()

    }

    func drawMoonPath() {

        let moonPath: UIBezierPath = UIBezierPath()
        moonPath.move(to: CGPoint(x: -1.41, y: -4.99))
        moonPath.addCurve(to: CGPoint(x: -4.99, y: -0.12), controlPoint1: CGPoint(x: -3.48, y: -4.34), controlPoint2: CGPoint(x: -4.99, y: -2.4))
        moonPath.addCurve(to: CGPoint(x: 0.12, y: 4.99), controlPoint1: CGPoint(x: -4.99, y: 2.7), controlPoint2: CGPoint(x: -2.7, y: 4.99))
        moonPath.addCurve(to: CGPoint(x: 4.99, y: 1.41), controlPoint1: CGPoint(x: 2.4, y: 4.99), controlPoint2: CGPoint(x: 4.34, y: 3.48))
        moonPath.addCurve(to: CGPoint(x: 2.04, y: 2.49), controlPoint1: CGPoint(x: 4.2, y: 2.09), controlPoint2: CGPoint(x: 3.17, y: 2.49))
        moonPath.addCurve(to: CGPoint(x: -2.49, y: -2.04), controlPoint1: CGPoint(x: -0.46, y: 2.49), controlPoint2: CGPoint(x: -2.49, y: 0.46))
        moonPath.addCurve(to: CGPoint(x: -1.41, y: -4.99), controlPoint1: CGPoint(x: -2.49, y: -3.17), controlPoint2: CGPoint(x: -2.09, y: -4.2))
        moonPath.close()
        moonPath.usesEvenOddFillRule = true
        self.circleEndOriginal.setFill()
        moonPath.fill()

    }

    func drawBellPath() {

        self.context?.saveGState()
        self.context?.translateBy(x: -58, y: 29.5)
        self.context?.rotate(by: -dayIconAngle * CGFloat.pi/180)

        let bellPath: UIBezierPath = UIBezierPath()
        bellPath.move(to: CGPoint(x: 4.5, y: 3.07))
        bellPath.addCurve(to: CGPoint(x: 1.29, y: 3.9), controlPoint1: CGPoint(x: 4.5, y: 3.07), controlPoint2: CGPoint(x: 2.79, y: 3.64))
        bellPath.addCurve(to: CGPoint(x: 0, y: 5), controlPoint1: CGPoint(x: 1.19, y: 4.52), controlPoint2: CGPoint(x: 0.65, y: 5))
        bellPath.addCurve(to: CGPoint(x: -1.28, y: 3.89), controlPoint1: CGPoint(x: -0.65, y: 5), controlPoint2: CGPoint(x: -1.19, y: 4.52))
        bellPath.addCurve(to: CGPoint(x: -4.5, y: 3.08), controlPoint1: CGPoint(x: -2.79, y: 3.63), controlPoint2: CGPoint(x: -4.5, y: 3.08))
        bellPath.addCurve(to: CGPoint(x: -2.83, y: 0.56), controlPoint1: CGPoint(x: -3.9, y: 2.34), controlPoint2: CGPoint(x: -2.81, y: 1.35))
        bellPath.addLine(to: CGPoint(x: -2.88, y: -1.04))
        bellPath.addCurve(to: CGPoint(x: -0.89, y: -4.22), controlPoint1: CGPoint(x: -2.87, y: -2.58), controlPoint2: CGPoint(x: -2.34, y: -3.85))
        bellPath.addCurve(to: CGPoint(x: 0, y: -5), controlPoint1: CGPoint(x: -0.83, y: -4.66), controlPoint2: CGPoint(x: -0.45, y: -5))
        bellPath.addCurve(to: CGPoint(x: 0.89, y: -4.22), controlPoint1: CGPoint(x: 0.46, y: -5), controlPoint2: CGPoint(x: 0.84, y: -4.66))
        bellPath.addCurve(to: CGPoint(x: 2.93, y: -1.03), controlPoint1: CGPoint(x: 2.33, y: -3.86), controlPoint2: CGPoint(x: 2.91, y: -2.58))
        bellPath.addLine(to: CGPoint(x: 2.89, y: 0.56))
        bellPath.addCurve(to: CGPoint(x: 4.5, y: 3.07), controlPoint1: CGPoint(x: 2.87, y: 1.36), controlPoint2: CGPoint(x: 3.87, y: 2.39))
        bellPath.close()
        bellPath.usesEvenOddFillRule = true
        self.circleEndOriginal.setFill()
        bellPath.fill()

    }

    func drawWakePoint() {

        // TimeGroup
        self.context?.saveGState()
        self.context?.translateBy(x: 78, y: 97)
        self.context?.rotate(by: -90 * CGFloat.pi/180)

        self.context?.saveGState()
        self.context?.rotate(by: -dayFrameAngle * CGFloat.pi/180)

        // WakePoint drawing
        self.context?.saveGState()
        self.context?.translateBy(x: -6.44, y: 3.28)
        self.context?.rotate(by: -27 * CGFloat.pi/180)

        let wakePointPath: UIBezierPath = UIBezierPath(ovalIn: CGRect(x: -65.78, y: -8, width: 16, height: 16))
        self.centerBackground.setFill()
        wakePointPath.fill()
        self.centerBackground.setStroke()
        wakePointPath.lineWidth = 1.75
        wakePointPath.stroke()

    }

    func drawSleepPoint() {

        self.context?.saveGState()
        self.context?.rotate(by: -(nightFrameAngle - 720) * CGFloat.pi/180)

        // SleepPoint drawing
        self.context?.saveGState()
        self.context?.translateBy(x: -6.25, y: -3.61)
        self.context?.rotate(by: -510 * CGFloat.pi/180)

        let sleepPointPath: UIBezierPath = UIBezierPath(ovalIn: CGRect(x: 49.78, y: -8, width: 16, height: 16))
        self.centerBackground.setFill()
        sleepPointPath.fill()
        self.centerBackground.setStroke()
        sleepPointPath.lineWidth = 1.7
        sleepPointPath.stroke()

        self.restoreState()

        // MoonIcon
        self.context?.saveGState()
        self.context?.translateBy(x: -51.77, y: -37.47)
        self.context?.rotate(by: 90 * CGFloat.pi/180)

        // Sleep
        self.context?.saveGState()
        self.context?.translateBy(x: 4.99, y: 4.99)
        self.context?.rotate(by: -nightIconAngle * CGFloat.pi/180)

    }

    func drawMinutePointers() {

        // MinutePointers
        self.context?.saveGState()
        self.context?.translateBy(x: 78, y: 97)
        self.context?.rotate(by: -360 * CGFloat.pi/180)

        self.drawMinuteGroup(group: (CGPoint(x: 0, y: 1), -7.5), pointer: (CGPoint(x: 0, y: pointers4Y), CGPoint(x: 0, y: 0)), opposite: (CGPoint(x: -0, y: pointersY), CGPoint(x: 0, y: 0)))

        self.restoreState(times: 2)

        self.drawMinuteGroup(group: (CGPoint(x: 0, y: 1), -15), pointer: (CGPoint(x: -0, y: pointers4Y), CGPoint(x: 0, y: -0)), opposite: (CGPoint(x: -0, y: pointersY), CGPoint(x: 0, y: 0)))

        self.restoreState(times: 2)

        self.drawMinuteGroup(group: (CGPoint(x: 0, y: 1), -22.5), pointer: (CGPoint(x: -0, y: pointers4Y), CGPoint(x: 0, y: 0)), opposite: (CGPoint(x: -0, y: pointersY), CGPoint(x: 0, y: 0)))

        self.restoreState(times: 2)

        self.drawMinuteGroup(group: (nil, -37.5), pointer: (CGPoint(x: 0, y: pointers2Y), CGPoint(x: 0, y: 0)), opposite: (CGPoint(x: 0, y: pointers3Y), CGPoint(x: -0, y: 0)))

        self.restoreState(times: 2)

        self.drawMinuteGroup(group: (nil, -45), pointer: (CGPoint(x: -0, y: pointers2Y), CGPoint(x: -0, y: 0)), opposite: (CGPoint(x: -0, y: pointers3Y), CGPoint(x: 0, y: 0)))

        self.restoreState(times: 2)

        self.drawMinuteGroup(group: (nil, -52.5), pointer: (CGPoint(x: -0, y: pointers2Y), CGPoint(x: -0, y: 0)), opposite: (CGPoint(x: -0, y: pointers3Y), CGPoint(x: -0, y: 0)))

        self.restoreState(times: 2)

        self.drawMinuteGroup(group: (nil, -97.5), pointer: (CGPoint(x: -0, y: pointers2Y), CGPoint(x: 0, y: -0)), opposite: (CGPoint(x: -0, y: pointers3Y), CGPoint(x: 0, y: -0)))

        self.restoreState(times: 2)

        self.drawMinuteGroup(group: (nil, -105), pointer: (CGPoint(x: -0, y: pointers2Y), CGPoint(x: 0, y: -0)), opposite: (CGPoint(x: -0, y: pointers3Y), CGPoint(x: 0, y: 0)))

        self.restoreState(times: 2)

        self.drawMinuteGroup(group: (nil, -112.5), pointer: (CGPoint(x: -0, y: pointers2Y), CGPoint(x: 0, y: 0)), opposite: (CGPoint(x: -0, y: pointers3Y), CGPoint(x: -0, y: 0)))

        self.restoreState(times: 2)

        self.drawMinuteGroup(group: (nil, -127.5), pointer: (CGPoint(x: -0, y: pointers2Y), CGPoint(x: -0, y: -0)), opposite: (CGPoint(x: -0, y: pointers3Y), CGPoint(x: -0, y: -0)))

        self.restoreState(times: 2)

        self.drawMinuteGroup(group: (nil, -135), pointer: (CGPoint(x: -0, y: pointers2Y), CGPoint(x: 0, y: -0)), opposite: (CGPoint(x: -0, y: pointers3Y), CGPoint(x: 0, y: -0)))

        self.restoreState(times: 2)

        self.drawMinuteGroup(group: (nil, -142.5), pointer: (CGPoint(x: -0, y: pointers2Y), CGPoint(x: -0, y: -0)), opposite: (CGPoint(x: -0, y: pointers3Y), CGPoint(x: -0, y: -0)))

        self.restoreState(times: 2)

        self.drawMinuteGroup(group: (CGPoint(x: 0.08, y: -0.05), -157.5), pointer: (CGPoint(x: -0, y: pointers2Y), CGPoint(x: -0, y: 0)), opposite: (CGPoint(x: -0, y: pointers3Y), CGPoint(x: -0, y: 0)))

        self.restoreState(times: 2)

        self.drawMinuteGroup(group: (CGPoint(x: 0.08, y: -0.05), -165), pointer: (CGPoint(x: 0, y: pointers2Y), CGPoint(x: 0, y: 0)), opposite: (CGPoint(x: 0, y: pointers3Y), CGPoint(x: 0, y: -0)))

        self.restoreState(times: 2)

        self.drawMinuteGroup(group: (CGPoint(x: 0.08, y: -0.05), -172.5), pointer: (CGPoint(x: 0, y: pointers2Y), CGPoint(x: -0, y: 0)), opposite: (CGPoint(x: 0, y: pointers3Y), CGPoint(x: -0, y: 0)))

        self.restoreState(times: 2)

        self.drawMinuteGroup(group: (CGPoint(x: -1.05, y: -0.08), 112.5), pointer: (CGPoint(x: 0, y: self.pointers4Y), CGPoint(x: 0, y: 0)), opposite: (CGPoint(x: 0, y: self.pointersY), CGPoint(x: 0, y: 0)))

        self.restoreState(times: 2)
        
        self.drawMinuteGroup(group: (CGPoint(x: -1.05, y: -0.08), 105), pointer: (CGPoint(x: 0, y: self.pointers4Y), CGPoint(x: 0, y: 0)), opposite: (CGPoint(x: 0, y: self.pointersY), CGPoint(x: 0, y: 0)))

        self.restoreState(times: 2)
        
        self.drawMinuteGroup(group: (CGPoint(x: -1.05, y: -0.08), 97.5), pointer: (CGPoint(x: -0, y: self.pointers4Y), CGPoint(x: 0, y: -0)), opposite: (CGPoint(x: 0, y: self.pointersY), CGPoint(x: 0, y: 0)))

    }

    func drawMinuteGroup(group: (translate: CGPoint?, rotate: CGFloat), pointer: (translate: CGPoint, position: CGPoint), opposite: (translate: CGPoint, position: CGPoint)) {

        self.context?.saveGState()

        if let translate: CGPoint = group.translate { self.context?.translateBy(x: translate.x, y: translate.y) }
        self.context?.rotate(by: group.rotate * CGFloat.pi/180)

        self.drawMinuteWrap(translate: pointer.translate, point: pointer.position)

        self.restoreState()

        self.drawMinuteWrap(translate: opposite.translate, point: pointer.position)

    }
    
    func drawMinuteWrap(translate: CGPoint, point: CGPoint) {
        
        self.context?.saveGState()
        self.context?.translateBy(x: translate.x, y: translate.y)
        
        self.drawMinutePointer(point)
        
    }
    
    func drawMinutePointer(_ point: CGPoint) {
        
        let minutePath: UIBezierPath = UIBezierPath()
        minutePath.move(to: point)
        minutePath.addLine(to: CGPoint(x: 0, y: self.hourPointerHeight))
        minutePath.addLine(to: CGPoint(x: 0, y: self.hourPointerHeight))
        self.thinPointer.setFill()
        minutePath.fill()
        self.thinPointer.setStroke()
        minutePath.lineWidth = self.minutePointerWidth
        minutePath.stroke()
        
    }
    
    func drawHourPointers() {
        
        self.context?.saveGState()
        self.context?.translateBy(x: 78, y: 97)
        self.context?.rotate(by: -360 * CGFloat.pi/180)
        
        self.drawHourGroup(rotate: -90)

        self.restoreState()

        self.drawHourPointer(y: self.pointer12Y)
        self.drawHourPointer(y: self.pointer6Y)
        
        self.drawHourGroup(rotate: -30)
        self.drawHourGroup(rotate: -90)

        self.restoreState(times: 2)
        
        self.drawHourGroup(rotate: -60)
        self.drawHourGroup(rotate: -90)
        
    }
    
    func drawHourGroup(rotate: CGFloat) {
        
        self.context?.saveGState()
        self.context?.rotate(by: rotate * CGFloat.pi/180)
        
        self.drawHourPointer(y: self.pointers2Y)
        self.drawHourPointer(y: self.pointers3Y)
        
    }
    
    func drawHourPointer(y: CGFloat) {
        
        let hourPath: UIBezierPath = UIBezierPath(rect: CGRect(x: -0.5, y: y, width: self.hourPointerWidth, height: self.hourPointerHeight))
        UIColor.gray.setFill()
        hourPath.fill()
        
    }

    func restoreState(times: Int = 1) { for _ in 0 ..< times { self.context?.restoreGState() } }
    
    
}
