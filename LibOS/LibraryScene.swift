import SwiftUI
import SceneKit

private extension Point3 {
    var vector: SCNVector3 { SCNVector3(x, y, z) }
}

protocol LibrarySceneProvider {
    func makeScene(configuration: NavigationConfiguration) throws -> SCNScene
}

struct ImportedLibrarySceneProvider: LibrarySceneProvider {
    func makeScene(configuration: NavigationConfiguration) throws -> SCNScene {
        guard let filename = configuration.modelFilename,
              let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
            throw CocoaError(.fileNoSuchFile)
        }
        let imported: SCNScene
        if url.pathExtension.lowercased() == "obj" {
            imported = try WavefrontSceneLoader.load(url: url)
        } else {
            imported = try SCNScene(url: url, options: nil)
        }
        let scene = SCNScene()
        let alignment = SCNNode()
        alignment.name = "buildingMesh"
        let transform = configuration.modelTransform
        alignment.scale = transform.scale.vector
        alignment.eulerAngles = transform.rotation.vector
        alignment.position = transform.translation.vector
        for child in imported.rootNode.childNodes { alignment.addChildNode(child) }
        // The supplied OBJ has no MTL. Use explicit, reproducible materials.
        alignment.enumerateChildNodes { node, _ in
            guard let geometry = node.geometry else { return }
            let material = SCNMaterial()
            let name = node.name ?? ""
            material.diffuse.contents = name.hasPrefix("Arpuse") ? UIColor(red: 0.37, green: 0.55, blue: 0.62, alpha: 1) : UIColor(red: 0.82, green: 0.80, blue: 0.73, alpha: 1)
            material.isDoubleSided = true
            geometry.materials = [material]
        }
        scene.rootNode.addChildNode(alignment)
        ProceduralLibrarySceneProvider.addShelves(configuration: configuration, to: scene.rootNode)
        return scene
    }
}

struct ProceduralLibrarySceneProvider: LibrarySceneProvider {
    func makeScene(configuration: NavigationConfiguration) throws -> SCNScene {
        let scene = SCNScene()
        let root = scene.rootNode
        func box(_ width: CGFloat, _ height: CGFloat, _ length: CGFloat, _ x: Double, _ y: Double, _ z: Double, _ color: UIColor) {
            let geometry = SCNBox(width: width, height: height, length: length, chamferRadius: 0.06)
            geometry.firstMaterial?.diffuse.contents = color
            let node = SCNNode(geometry: geometry)
            node.position = SCNVector3(x, y, z)
            root.addChildNode(node)
        }
        box(18, 0.2, 20, 0, -0.1, 0, UIColor(red: 0.89, green: 0.87, blue: 0.81, alpha: 1))
        // Low cutaway walls keep the route visible while defining the building.
        box(18, 1, 0.25, 0, 0.5, -10, .white)
        box(0.25, 1, 20, -9, 0.5, 0, .white)
        box(0.25, 1, 20, 9, 0.5, 0, .white)
        box(7, 0.6, 0.25, -5.5, 0.3, 10, .white)
        box(7, 0.6, 0.25, 5.5, 0.3, 10, .white)
        box(2, 0.025, 18, 0, 0.015, -0.5, UIColor(white: 0.97, alpha: 1))
        for z in [4.0, -1, -6] {
            box(14, 0.025, 1.1, 0, 0.02, z, UIColor(white: 0.97, alpha: 1))
        }
        Self.addShelves(configuration: configuration, to: root)
        box(2.5, 1, 1.2, 5, 0.5, 8.6, .systemTeal)
        root.addChildNode(Self.label("INFORMATION", at: Point3(x: 3.7, y: 1.6, z: 8.6)))
        for x in [-6.0, -3.8] {
            box(1.4, 0.12, 1.1, x, 0.8, 8.5, .brown)
            box(0.15, 0.8, 0.15, x, 0.4, 8.5, .darkGray)
        }
        root.addChildNode(Self.label("READING", at: Point3(x: -6.5, y: 1.5, z: 9)))
        root.addChildNode(Self.label("ENTRANCE", at: Point3(x: -1.3, y: 0.1, z: 9.7)))
        return scene
    }

    static func addShelves(configuration: NavigationConfiguration, to root: SCNNode) {
        for shelf in configuration.shelves {
            let shelfRoot = SCNNode()
            shelfRoot.name = shelf.id
            shelfRoot.position = shelf.position.vector
            let wood = UIColor(red: 0.37, green: 0.30, blue: 0.22, alpha: 1)
            for height in [0.15, 0.85, 1.55, 2.25] {
                let board = SCNBox(width: 3.2, height: 0.12, length: 0.65, chamferRadius: 0.025)
                board.firstMaterial?.diffuse.contents = wood
                let node = SCNNode(geometry: board)
                node.position.y = Float(height)
                shelfRoot.addChildNode(node)
            }
            for x in [-1.55, 1.55] {
                let panel = SCNBox(width: 0.1, height: 2.3, length: 0.65, chamferRadius: 0.025)
                panel.firstMaterial?.diffuse.contents = wood
                let node = SCNNode(geometry: panel)
                node.position = SCNVector3(x, 1.15, 0)
                shelfRoot.addChildNode(node)
            }
            for level in 0..<3 {
                for index in 0..<10 {
                    let book = SCNBox(width: 0.21, height: CGFloat(0.42 + Double(index % 3) * 0.05), length: 0.43, chamferRadius: 0.01)
                    book.firstMaterial?.diffuse.contents = [UIColor.systemTeal, UIColor.systemIndigo, UIColor.brown, UIColor.systemOrange][index % 4]
                    let node = SCNNode(geometry: book)
                    node.position = SCNVector3(-1.3 + Double(index) * 0.28, 0.44 + Double(level) * 0.7, 0)
                    shelfRoot.addChildNode(node)
                }
            }
            root.addChildNode(shelfRoot)
            root.addChildNode(Self.label(shelf.label, at: Point3(x: shelf.position.x - 1.4, y: shelf.position.y + 2.6, z: shelf.position.z)))
        }
    }

    static func label(_ text: String, at point: Point3) -> SCNNode {
        let geometry = SCNText(string: text, extrusionDepth: 0.01)
        geometry.font = .systemFont(ofSize: 0.45, weight: .semibold)
        geometry.flatness = 0.4
        geometry.firstMaterial?.diffuse.contents = UIColor(red: 0.08, green: 0.16, blue: 0.24, alpha: 1)
        let node = SCNNode(geometry: geometry)
        node.position = point.vector
        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = .Y
        node.constraints = [billboard]
        return node
    }
}

final class LibrarySceneController {
    let scene: SCNScene
    let camera = SCNNode()
    let routeRoot = SCNNode()
    let graph: NavigationConfiguration
    private var lastKey = ""
    private var lastCommand = -1
    let usedFallback: Bool

    init(graph: NavigationConfiguration) {
        self.graph = graph
        if graph.modelFilename != nil, let imported = try? ImportedLibrarySceneProvider().makeScene(configuration: graph) {
            scene = imported
            usedFallback = false
        } else {
            if graph.modelFilename != nil {
                // Same fixed shelf coordinates even when the building cannot load.
                scene = SCNScene()
                let floor = SCNBox(width: 170, height: 0.2, length: 44, chamferRadius: 0)
                floor.firstMaterial?.diffuse.contents = UIColor(white: 0.88, alpha: 1)
                let node = SCNNode(geometry: floor)
                node.position.y = 0.05
                scene.rootNode.addChildNode(node)
                ProceduralLibrarySceneProvider.addShelves(configuration: graph, to: scene.rootNode)
            } else {
                scene = (try? ProceduralLibrarySceneProvider().makeScene(configuration: graph)) ?? SCNScene()
            }
            usedFallback = true
        }
        scene.background.contents = UIColor(red: 0.93, green: 0.93, blue: 0.89, alpha: 1)
        scene.rootNode.addChildNode(routeRoot)
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.orthographicScale = 24
        camera.camera?.zFar = 2000
        scene.rootNode.addChildNode(camera)
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 650
        scene.rootNode.addChildNode(ambient)
        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.intensity = 950
        sun.eulerAngles = SCNVector3(-0.8, -0.5, 0)
        scene.rootNode.addChildNode(sun)
        focus(points: graph.nodes.map(\.position), view: nil)
    }

    func update(book: Book?, start: String, command: Int, mode: String, view: SCNView) {
        let key = "\(book?.id ?? "")|\(start)"
        let selectionChanged = key != lastKey
        guard selectionChanged || command != lastCommand else { return }
        if selectionChanged || command != lastCommand {
            setBuildingOverview(!selectionChanged && mode == "building")
        }
        let shelf = graph.shelves.first { $0.id == book?.shelfID }
        let path = shelf.flatMap { RoutingEngine.path(from: start, to: $0.accessNodeID, graph: graph) }
        if key != lastKey {
            lastKey = key
            routeRoot.childNodes.forEach { $0.removeFromParentNode() }
            for location in graph.shelves {
                scene.rootNode.childNode(withName: location.id, recursively: true)?.enumerateChildNodes { node, _ in
                    node.geometry?.firstMaterial?.emission.contents = location.id == shelf?.id ? UIColor(red: 0.0, green: 0.25, blue: 0.28, alpha: 1) : UIColor.black
                }
            }
            if let startNode = graph.nodes.first(where: { $0.id == start }) { marker(startNode.position, color: .systemIndigo) }
            if let path, let shelf {
                for (a, b) in zip(path, path.dropFirst()) { segment(a.position, b.position) }
                if let end = path.last {
                    marker(end.position, color: .systemTeal)
                    routeRoot.addChildNode(ProceduralLibrarySceneProvider.label("YOUR BOOK · \(shelf.id)", at: Point3(x: end.position.x - 1.5, y: end.position.y + 3.3, z: end.position.z)))
                }
                focus(points: path.map(\.position), view: view)
            }
        }
        if command != lastCommand && !selectionChanged {
            lastCommand = command
            if mode == "building" {
                focus(points: [Point3(x: -85, y: 0, z: -22), Point3(x: 85, y: 74, z: 22)], view: view)
            } else if mode == "destination", let shelf {
                focus(points: [shelf.position], view: view)
            } else if mode == "route", let path {
                focus(points: path.map(\.position), view: view)
            } else {
                focus(points: graph.nodes.map(\.position), view: view)
            }
        }
        lastCommand = command
    }

    private func setBuildingOverview(_ overview: Bool) {
        guard let mesh = scene.rootNode.childNode(withName: "buildingMesh", recursively: false) else { return }
        // Object names are authored in the supplied OBJ; retain only floor 1
        // in the navigation cutaway. The complete mesh remains available.
        for node in mesh.childNodes {
            let name = node.name ?? ""
            node.isHidden = overview ? name.hasPrefix("Konteksts") : !name.hasPrefix("Stavs_1_")
        }
        routeRoot.isHidden = overview
        for shelf in graph.shelves {
            scene.rootNode.childNode(withName: shelf.id, recursively: false)?.isHidden = overview
        }
    }

    private func marker(_ p: Point3, color: UIColor) {
        let shape = SCNCylinder(radius: 0.3, height: 0.16)
        shape.firstMaterial?.diffuse.contents = color
        shape.firstMaterial?.emission.contents = color.withAlphaComponent(0.3)
        let node = SCNNode(geometry: shape)
        node.position = SCNVector3(p.x, p.y + 0.16, p.z)
        routeRoot.addChildNode(node)
    }

    private func segment(_ a: Point3, _ b: Point3) {
        let length = a.distance(to: b)
        guard length > 0 else { return }
        let shape = SCNBox(width: 0.16, height: 0.06, length: CGFloat(length), chamferRadius: 0.03)
        shape.firstMaterial?.diffuse.contents = UIColor.systemTeal
        shape.firstMaterial?.emission.contents = UIColor(red: 0, green: 0.35, blue: 0.5, alpha: 1)
        let node = SCNNode(geometry: shape)
        node.position = SCNVector3((a.x + b.x) / 2, (a.y + b.y) / 2 + 0.09, (a.z + b.z) / 2)
        node.eulerAngles.y = Float(atan2(b.x - a.x, b.z - a.z))
        routeRoot.addChildNode(node)
    }

    private func focus(points: [Point3], view: SCNView?) {
        guard !points.isEmpty else { return }
        let minX = points.map(\.x).min() ?? 0
        let maxX = points.map(\.x).max() ?? 0
        let minZ = points.map(\.z).min() ?? 0
        let maxZ = points.map(\.z).max() ?? 0
        let center = SCNVector3((minX + maxX) / 2, ((points.map(\.y).min() ?? 0) + (points.map(\.y).max() ?? 0)) / 2, (minZ + maxZ) / 2)
        let span = max(20, max(maxX - minX, maxZ - minZ))
        camera.position = SCNVector3(center.x + Float(span), center.y + Float(span * 1.5), center.z + Float(span * 1.4))
        camera.look(at: center)
        camera.camera?.orthographicScale = max(8, max(maxX - minX, maxZ - minZ) * 0.65 + 5)
        view?.pointOfView = camera
        view?.defaultCameraController.target = center
    }
}

struct LibrarySceneView: UIViewRepresentable {
    let graph: NavigationConfiguration
    let book: Book?
    let start: String
    let command: Int
    let mode: String

    func makeCoordinator() -> LibrarySceneController { LibrarySceneController(graph: graph) }
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = context.coordinator.scene
        view.pointOfView = context.coordinator.camera
        view.allowsCameraControl = true
        view.defaultCameraController.interactionMode = .orbitTurntable
        view.defaultCameraController.minimumVerticalAngle = 15
        view.defaultCameraController.maximumVerticalAngle = 85
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 30
        view.accessibilityLabel = "Interactive demonstration library map. Drag to rotate and pinch to zoom. Text directions are below."
        return view
    }
    func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.update(book: book, start: start, command: command, mode: mode, view: view)
    }
}
