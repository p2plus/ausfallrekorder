import AppKit
import Foundation

// Source artwork. Rebuild with: swift scripts/make-icon.swift
let size = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
NSColor(calibratedRed: 0.075, green: 0.20, blue: 0.18, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896), xRadius: 200, yRadius: 200).fill()
let pulse = NSBezierPath()
pulse.move(to: NSPoint(x: 230, y: 512))
for p in [NSPoint(x: 340, y: 512), NSPoint(x: 414, y: 666), NSPoint(x: 492, y: 358), NSPoint(x: 568, y: 512), NSPoint(x: 650, y: 512)] {
    pulse.line(to: p)
}
pulse.lineWidth = 58
pulse.lineCapStyle = .round
pulse.lineJoinStyle = .round
NSColor(calibratedRed: 0.94, green: 0.96, blue: 0.88, alpha: 1).setStroke()
pulse.stroke()
NSColor(calibratedRed: 0.98, green: 0.66, blue: 0.27, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: 716, y: 468, width: 88, height: 88)).fill()
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
let data = bitmap.representation(using: .png, properties: [:])!
try FileManager.default.createDirectory(atPath: "Resources", withIntermediateDirectories: true)
try data.write(to: URL(fileURLWithPath: "Resources/AppIcon.png"))
