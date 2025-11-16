import SwiftUI
import SceneKit
import UIKit

struct BlackjackSceneView: UIViewRepresentable {
    @Binding var playerHand: [Deck]?
    @Binding var dealerHand: [Deck]?
    @Binding var gameState: GameState
    
    private let sceneView = SCNView()
    private let scene = SCNScene()
    
    // Node references
    private var tableNode: SCNNode?
    private var playerCardsNode: SCNNode?
    private var dealerCardsNode: SCNNode?
    
    // Animation properties
    private var cardAnimationDuration: TimeInterval = 1.0
    private var cardRotationAnimationDuration: TimeInterval = 0.5
    
//    init(playerHand: Binding<[Deck]?>, dealerHand: Binding<[Deck]?>, gameState: Binding<GameState>) {
//        self._playerHand = playerHand
//        self._dealerHand = dealerHand
//        self._gameState = gameState
//    }
    
    func makeUIView(context: Context) -> SCNView {
        setupScene()
        setupCamera()
        setupLights()
        setupTable()
        setupCardHolders()
        
        sceneView.scene = scene
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.isPlaying = true
        sceneView.backgroundColor = UIColor(.black)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update cards when hands change
        updatePlayerCards()
        updateDealerCards()
    }
    
    private func setupScene() {
        // Set scene background
        scene.background.contents = UIColor(.darkGray)
    }
    
    private func setupCamera() {
        // Create a camera node with first-person俯视视角
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 20, z: 0) // 俯视视角
        cameraNode.eulerAngles = SCNVector3(x: -Float.pi/2, y: 0, z: 0) // 旋转90度向下看
        scene.rootNode.addChildNode(cameraNode)
    }
    
    private func setupLights() {
        // Ambient light for general illumination
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor(white: 0.4, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLightNode)
        
        // Main directional light (simulating overhead light)
        let directionalLightNode = SCNNode()
        directionalLightNode.light = SCNLight()
        directionalLightNode.light?.type = .directional
        directionalLightNode.light?.color = UIColor(white: 0.8, alpha: 1.0)
        directionalLightNode.position = SCNVector3(x: 0, y: 15, z: 15)
        directionalLightNode.eulerAngles = SCNVector3(x: -Float.pi/4, y: 0, z: 0)
        scene.rootNode.addChildNode(directionalLightNode)
        
        // Point light for table illumination
        let pointLightNode = SCNNode()
        pointLightNode.light = SCNLight()
        pointLightNode.light?.type = .point
        pointLightNode.light?.color = UIColor(red: 0.9, green: 0.8, blue: 0.7, alpha: 1.0)
        pointLightNode.light?.intensity = 1500
        pointLightNode.position = SCNVector3(x: 0, y: 10, z: 0)
        scene.rootNode.addChildNode(pointLightNode)
    }
    
    private func setupTable() {
        // Create table shape (oval)
        let tableGeometry = SCNCylinder(radius: 12, height: 1)
        
        // Apply wood texture
        if let woodTexture = UIImage(named: "wood") {
            tableGeometry.firstMaterial?.diffuse.contents = woodTexture
            tableGeometry.firstMaterial?.specular.contents = UIColor.white
            tableGeometry.firstMaterial?.shininess = 30
        }
        
        // Create table node
        tableNode = SCNNode(geometry: tableGeometry)
        tableNode?.position = SCNVector3(x: 0, y: -0.5, z: 0)
        scene.rootNode.addChildNode(tableNode!)
        
        // Add table border
        let borderGeometry = SCNTorus(ringRadius: 12, pipeRadius: 0.3)
        borderGeometry.firstMaterial?.diffuse.contents = UIColor.black
        let borderNode = SCNNode(geometry: borderGeometry)
        borderNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(borderNode)
    }
    
    private func setupCardHolders() {
        // Player cards holder node
        playerCardsNode = SCNNode()
        playerCardsNode?.position = SCNVector3(x: 0, y: 0.2, z: 8)
        scene.rootNode.addChildNode(playerCardsNode!)
        
        // Dealer cards holder node
        dealerCardsNode = SCNNode()
        dealerCardsNode?.position = SCNVector3(x: 0, y: 0.2, z: -8)
        scene.rootNode.addChildNode(dealerCardsNode!)
    }
    
    private func updatePlayerCards() {
        guard let playerHand = playerHand else { return }
        
        // Remove all existing player cards
        playerCardsNode?.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        
        // Add new player cards
        for (index, card) in playerHand.enumerated() {
            let cardNode = createCardNode(card: card, isFaceUp: true)
            
            // Calculate position with spread
            let spread = Float(index - playerHand.count/2) * 2.0
            cardNode.position = SCNVector3(x: spread, y: 0, z: 0)
            
            // Add to player cards node
            playerCardsNode?.addChildNode(cardNode)
            
            // Animate card entrance
            animateCardEntrance(cardNode: cardNode)
        }
    }
    
    private func updateDealerCards() {
        guard let dealerHand = dealerHand else { return }
        
        // Remove all existing dealer cards
        dealerCardsNode?.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        
        // Add new dealer cards
        for (index, card) in dealerHand.enumerated() {
            let isFaceUp = gameState == .finished || index == 1 // Only show second card when game is finished
            let cardNode = createCardNode(card: card, isFaceUp: isFaceUp)
            
            // Calculate position with spread
            let spread = Float(index - dealerHand.count/2) * 2.0
            cardNode.position = SCNVector3(x: spread, y: 0, z: 0)
            
            // Add to dealer cards node
            dealerCardsNode?.addChildNode(cardNode)
            
            // Animate card entrance
            animateCardEntrance(cardNode: cardNode)
        }
    }
    
    private func createCardNode(card: Deck, isFaceUp: Bool) -> SCNNode {
        // Card dimensions
        let cardWidth: CGFloat = 2.5
        let cardHeight: CGFloat = 3.5
        let cardThickness: CGFloat = 0.05
        
        // Create card geometry
        let cardGeometry = SCNBox(width: cardWidth, height: cardHeight, length: cardThickness, chamferRadius: 0.1)
        
        // Set card material
        let cardMaterial = SCNMaterial()
        
        if isFaceUp {
            // Use card image
            let cardImageName = card.loc.replacingOccurrences(of: "assets/PlayingCardsPNG/", with: "").replacingOccurrences(of: ".png", with: "")
            cardMaterial.diffuse.contents = UIImage(named: cardImageName)
        } else {
            // Use back of card
            cardMaterial.diffuse.contents = UIImage(named: "0_back_of_card")
        }
        
        cardMaterial.specular.contents = UIColor.white
        cardMaterial.shininess = 10
        
        cardGeometry.materials = [cardMaterial]
        
        // Create card node
        let cardNode = SCNNode(geometry: cardGeometry)
        cardNode.eulerAngles = SCNVector3(x: Float.pi/2, y: 0, z: 0) // Rotate to lay flat
        
        return cardNode
    }
    
    private func animateCardEntrance(cardNode: SCNNode) {
        // Original position off-screen
        let startPosition = SCNVector3(x: 15, y: 5, z: 0)
        cardNode.position = startPosition
        
        // Animation: move to target position with rotation
        let moveAction = SCNAction.move(to: cardNode.position, duration: cardAnimationDuration)
        moveAction.timingMode = .easeInOut
        
        // Add rotation animation
        let rotateAction = SCNAction.rotateBy(x: 0, y: Float.pi * 2, z: 0, duration: cardRotationAnimationDuration)
        rotateAction.timingMode = .easeInOut
        
        // Run animations
        cardNode.runAction(SCNAction.sequence([rotateAction, moveAction]))
    }
}
