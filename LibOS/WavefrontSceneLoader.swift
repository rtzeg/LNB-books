import Foundation
import SceneKit

/// Preserves authored OBJ object boundaries for the floor cutaway.
/// The supplied model contains convex polygon faces; fan triangulation is
/// intentionally limited to that format. Materials are supplied by the app.
enum WavefrontSceneLoader {
    private struct VertexKey: Hashable {
        let x: Float
        let y: Float
        let z: Float
        let nx: Float
        let ny: Float
        let nz: Float
    }

    static func load(url: URL) throws -> SCNScene {
        let source = try String(contentsOf: url, encoding: .utf8)
        var positions: [SCNVector3] = []
        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var indices: [Int32] = []
        var vertexLookup: [VertexKey: Int32] = [:]
        var name = "Mesh"
        let scene = SCNScene()

        func flush() {
            guard !vertices.isEmpty else { return }
            let geometry = SCNGeometry(sources: [
                SCNGeometrySource(vertices: vertices),
                SCNGeometrySource(normals: normals)
            ], elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)])
            let node = SCNNode(geometry: geometry)
            node.name = name
            scene.rootNode.addChildNode(node)
            vertices.removeAll(keepingCapacity: true)
            normals.removeAll(keepingCapacity: true)
            indices.removeAll(keepingCapacity: true)
            vertexLookup.removeAll(keepingCapacity: true)
        }

        for line in source.split(whereSeparator: \.isNewline) {
            let parts = line.split(whereSeparator: \.isWhitespace)
            guard let prefix = parts.first else { continue }
            switch prefix {
            case "v":
                guard parts.count >= 4, let x = Float(parts[1]), let y = Float(parts[2]), let z = Float(parts[3]),
                      x.isFinite, y.isFinite, z.isFinite else { throw CocoaError(.fileReadCorruptFile) }
                positions.append(SCNVector3(x, y, z))
            case "o":
                flush()
                name = parts.dropFirst().joined(separator: " ")
            case "f":
                let face = try parts.dropFirst().map { token -> SCNVector3 in
                    guard let first = token.split(separator: "/").first, let raw = Int(first), raw != 0 else {
                        throw CocoaError(.fileReadCorruptFile)
                    }
                    let index = raw > 0 ? raw - 1 : positions.count + raw
                    guard positions.indices.contains(index) else { throw CocoaError(.fileReadCorruptFile) }
                    return positions[index]
                }
                guard face.count >= 3 else { throw CocoaError(.fileReadCorruptFile) }
                for index in 1..<(face.count - 1) {
                    let a = face[0], b = face[index], c = face[index + 1]
                    let u = SCNVector3(b.x - a.x, b.y - a.y, b.z - a.z)
                    let v = SCNVector3(c.x - a.x, c.y - a.y, c.z - a.z)
                    let cross = SCNVector3(u.y * v.z - u.z * v.y, u.z * v.x - u.x * v.z, u.x * v.y - u.y * v.x)
                    let length = sqrt(cross.x * cross.x + cross.y * cross.y + cross.z * cross.z)
                    guard length > 0 else { continue }
                    let normal = SCNVector3(cross.x / length, cross.y / length, cross.z / length)
                    // Share vertices only when both position and face normal match.
                    // This reduces GPU buffer size without smoothing sharp edges.
                    for point in [a, b, c] {
                        let key = VertexKey(x: point.x, y: point.y, z: point.z,
                                            nx: normal.x, ny: normal.y, nz: normal.z)
                        if let existing = vertexLookup[key] {
                            indices.append(existing)
                        } else {
                            let next = Int32(vertices.count)
                            vertexLookup[key] = next
                            vertices.append(point)
                            normals.append(normal)
                            indices.append(next)
                        }
                    }
                }
            default: break
            }
        }
        flush()
        guard !scene.rootNode.childNodes.isEmpty else { throw CocoaError(.fileReadCorruptFile) }
        return scene
    }
}
