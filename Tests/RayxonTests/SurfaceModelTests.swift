import Testing
import CoreGraphics
@testable import Rayxon

struct SurfaceModelTests {
    @Test func convertsCGBoundsToAppKitTopEdge() {
        // primary screen 1000 tall; CG rect at y=100 (from top), height 300 → AppKit top edge = 900
        let raw = RawWindow(number: 5, pid: 99, layer: 0, alpha: 1, bounds: CGRect(x: 10, y: 100, width: 400, height: 300))
        let s = SurfaceModel.support(from: raw, primaryHeight: 1000)
        #expect(s == Support(id: .window(5), top: 900, minX: 10, maxX: 410))
    }

    @Test func filtersNonStandableWindows() {
        let ok = RawWindow(number: 1, pid: 1, layer: 0, alpha: 1, bounds: CGRect(x: 0, y: 0, width: 400, height: 300))
        let tiny = RawWindow(number: 2, pid: 1, layer: 0, alpha: 1, bounds: CGRect(x: 0, y: 0, width: 50, height: 20))
        let overlay = RawWindow(number: 3, pid: 1, layer: 25, alpha: 1, bounds: CGRect(x: 0, y: 0, width: 400, height: 300))
        let ghost = RawWindow(number: 4, pid: 1, layer: 0, alpha: 0.0, bounds: CGRect(x: 0, y: 0, width: 400, height: 300))
        let mine = RawWindow(number: 6, pid: 42, layer: 0, alpha: 1, bounds: CGRect(x: 0, y: 0, width: 400, height: 300))
        let out = SurfaceModel.supports(from: [ok, tiny, overlay, ghost, mine], primaryHeight: 1000,
                                        selfPID: 42, isRegularApp: { _ in true })
        #expect(out.map(\.id) == [.window(1)])
    }

    @Test func excludesNonRegularApps() {
        let w = RawWindow(number: 1, pid: 7, layer: 0, alpha: 1, bounds: CGRect(x: 0, y: 0, width: 400, height: 300))
        let out = SurfaceModel.supports(from: [w], primaryHeight: 1000, selfPID: 0, isRegularApp: { $0 != 7 })
        #expect(out.isEmpty)
    }

    @Test func occludedPartsOfLowerWindowsAreRemoved() {
        // front window covers x 100..300 of the back window's top edge; back window is taller (top edge higher? no: lower)
        let front = RawWindow(number: 1, pid: 1, layer: 0, alpha: 1, bounds: CGRect(x: 100, y: 50, width: 200, height: 500))
        let back = RawWindow(number: 2, pid: 1, layer: 0, alpha: 1, bounds: CGRect(x: 0, y: 200, width: 400, height: 300))
        let out = SurfaceModel.supports(from: [front, back], primaryHeight: 1000, selfPID: 0, isRegularApp: { _ in true })
        // back's top edge (AppKit y=800) is split into [0,100] and [300,400]
        let backs = out.filter { $0.id == .window(2) }
        #expect(backs.count == 2)
        #expect(backs[0].minX == 0 && backs[0].maxX == 100)
        #expect(backs[1].minX == 300 && backs[1].maxX == 400)
        #expect(out.first?.id == .window(1))
    }
}
