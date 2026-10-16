import CoreGraphics

/// Minimal, Sendable snapshot of one on-screen window (CG coordinates, top-left origin).
struct RawWindow: Equatable, Sendable {
    var number: Int
    var pid: Int32
    var layer: Int
    var alpha: Double
    var bounds: CGRect
}

enum SurfaceModel {
    static let minWidth: CGFloat = 120
    static let minHeight: CGFloat = 60

    /// Converts a window's top edge into AppKit (bottom-left origin) space.
    static func support(from w: RawWindow, primaryHeight: CGFloat) -> Support {
        let top = Double(primaryHeight - w.bounds.minY)
        return Support(id: .window(w.number), top: top,
                       minX: Double(w.bounds.minX), maxX: Double(w.bounds.maxX))
    }

    /// Filters standable windows (front-to-back order preserved) and removes top-edge segments
    /// hidden behind windows in front of them.
    static func supports(from windows: [RawWindow], primaryHeight: CGFloat,
                         selfPID: Int32, isRegularApp: (Int32) -> Bool) -> [Support] {
        var rects: [CGRect] = []     // AppKit-space rects of accepted windows, front to back
        var out: [Support] = []
        for w in windows {
            guard w.layer == 0, w.alpha > 0.1, w.pid != selfPID else { continue }
            let rect = CGRect(x: w.bounds.minX, y: primaryHeight - w.bounds.maxY,
                              width: w.bounds.width, height: w.bounds.height)
            // Anything opaque occludes edges behind it, even if it is not standable itself.
            guard w.bounds.width >= minWidth, w.bounds.height >= minHeight, isRegularApp(w.pid) else {
                rects.append(rect); continue
            }
            let base = support(from: w, primaryHeight: primaryHeight)
            // subtract x-intervals covered by windows in front whose vertical span contains the edge
            var segments: [(Double, Double)] = [(base.minX, base.maxX)]
            for f in rects where f.minY < CGFloat(base.top) && f.maxY > CGFloat(base.top) {
                var next: [(Double, Double)] = []
                for (a, b) in segments {
                    let fa = Double(f.minX), fb = Double(f.maxX)
                    if fb <= a || fa >= b { next.append((a, b)); continue }
                    if fa > a { next.append((a, fa)) }
                    if fb < b { next.append((fb, b)) }
                }
                segments = next
            }
            for (a, b) in segments where b - a >= 24 {
                out.append(Support(id: base.id, top: base.top, minX: a, maxX: b))
            }
            rects.append(rect)
        }
        return out
    }
}
