import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet var sceneView: ARSCNView!
    
    // MARK: - Types
    enum ObjectPlacementMode {
        case freeform
        case plane
        case image
    }
    
    // MARK: - Properties
    let configuration = ARWorldTrackingConfiguration()
    var selectedNode: SCNNode?
    var objectMode: ObjectPlacementMode = .freeform {
        didSet {
            reloadConfiguration()
        }
    }
    
    var placedNodes = [SCNNode]()
    var planeNodes = [SCNNode]()
    
    var rootNode: SCNNode {
        return sceneView.scene.rootNode
    }
    
    // MARK: - Custom Methods
    func reloadConfiguration() {
        configuration.detectionImages = (objectMode == .image) ?
            ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) : nil
        
        configuration.planeDetection = [.horizontal]
        
        sceneView.session.run(configuration)
    }
    
    // MARK: - UIViewController Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadConfiguration()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // MARK: - Object Placement Methods
    func addNode(_ node: SCNNode, to parentNode: SCNNode) {
        let cloneNode = node.clone()
        parentNode.addChildNode(cloneNode)
        placedNodes.append(cloneNode)
    }
    
    func addNodeInFront(_ node: SCNNode) {
        guard let currentFrame = sceneView.session.currentFrame else { return }
        
        let transform = currentFrame.camera.transform
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -0.2
        node.simdTransform = matrix_multiply(transform, translation)
        
        addNode(node, to: rootNode)
    }
    
    func nodeAdded(_ node: SCNNode, for anchor: ARPlaneAnchor) {
        
    }
    
    func nodeAdded(_ node: SCNNode, for anchor: ARImageAnchor) {
        guard let selectedNode = selectedNode else { return }
        addNode(selectedNode, to: node)
    }
    
    // MARK: - Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let node = selectedNode else { return }
        guard let touch = touches.first else { return }
        
        switch objectMode {
            
        case .freeform:
            addNodeInFront(node)
            
        case .plane:
            break
            
        case .image:
            break
            
        }
    }

    // MARK: - Actions
    @IBAction func changeObjectMode(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            objectMode = .freeform
        case 1:
            objectMode = .plane
        case 2:
            objectMode = .image
        default:
            break
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showOptions" {
            let optionsViewController = segue.destination as! OptionsContainerViewController
            optionsViewController.delegate = self
        }
    }
}

// MARK: - OptionsViewControllerDelegate
extension ViewController: OptionsViewControllerDelegate {
    
    func objectSelected(node: SCNNode) {
        dismiss(animated: true, completion: nil)
        selectedNode = node
    }
    
    func togglePlaneVisualization() {
        dismiss(animated: true, completion: nil)
    }
    
    func undoLastObject() {
        
    }
    
    func resetScene() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let imageAnchor = anchor as? ARImageAnchor {
            nodeAdded(node, for: imageAnchor)
        } else if let planeAnchor = anchor as? ARPlaneAnchor {
            nodeAdded(node, for: planeAnchor)
        }
    }
}
