import XCTest
@testable import CubeZX

final class DecodeFaceletTests: XCTestCase {
    func testSamplePayloadDecodesToExpectedCenters() {
        let hex = "35 00 33 33 02 35 10 24 15 04 24 44 02 40 55 23 51 31 22 50 40 13 51 14 51 42 12"
        let bytes = Data(hex.split(separator: " ").map { UInt8($0, radix: 16)! })
        XCTAssertEqual(bytes.count, 27)
        let facelets = TornadoV4Adapter.decodeFaceletBytes(bytes)
        XCTAssertEqual(facelets.count, 54)

        let centers = (0..<6).map { facelets[$0 * 9 + 4] }
        XCTAssertEqual(centers, [.white, .yellow, .orange, .red, .green, .blue])

        // A few spot checks from the previously observed decoded faces
        // Up face first row should contain blue in position 0 after mapping
        XCTAssertEqual(facelets[0], .blue)
        // Front center should be green
        XCTAssertEqual(facelets[4*9 + 4], .green)
    }
}
