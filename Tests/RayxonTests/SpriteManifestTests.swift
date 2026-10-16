import Testing
import Foundation
@testable import Rayxon

struct SpriteManifestTests {
    @Test func decodesOutfitsAndStates() throws {
        let json = """
        {"atlas": {"idle": {"frames": 4, "fps": 6, "loop": true},
                   "fall": {"frames": 2, "fps": 12, "loop": false}}}
        """.data(using: .utf8)!
        let manifest = try SpriteManifest.decode(json)
        let idle = try #require(manifest.animation(outfit: "atlas", state: .idle))
        #expect(idle.frames == 4)
        #expect(idle.fps == 6)
        #expect(idle.loop == true)
        let fall = try #require(manifest.animation(outfit: "atlas", state: .fall))
        #expect(fall.loop == false)
        #expect(manifest.animation(outfit: "atlas", state: .walk) == nil)
        #expect(manifest.outfits == ["atlas"])
    }

    @Test func missingStateFallsBackToIdle() throws {
        let json = """
        {"atlas": {"idle": {"frames": 4, "fps": 6, "loop": true}}}
        """.data(using: .utf8)!
        let manifest = try SpriteManifest.decode(json)
        let anim = manifest.animationOrIdle(outfit: "atlas", state: .walk)
        #expect(anim?.frames == 4)
    }
}
