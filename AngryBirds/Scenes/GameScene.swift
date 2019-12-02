//
//  GameScene.swift
//  AngryBirds
//
//  Created by Emily Cheroske on 11/30/19.
//  Copyright © 2019 Emily Cheroske. All rights reserved.
//

import SpriteKit
import GameplayKit

enum RoundState {
    case ready, flying, finished, animating
}

class GameScene: SKScene {
    
    var mapNode = SKTileMapNode()
    let gameCamera = GameCamera()
    var panRecognizer = UIPanGestureRecognizer()
    var pinchRecognizer = UIPinchGestureRecognizer()
    var maxScale : CGFloat = 0
    var bird = Bird(type: .red)
    var birds = [
        Bird(type: .blue),
        Bird(type: .red),
        Bird(type: .yellow)
    ]
    var anchor = SKNode()
    var roundedState = RoundState.ready
    
    override func didMove(to view: SKView) {
        setupLevel()
        setupGestureRecognizers()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("::touchesBegan::")
        
        switch roundedState {
        case .ready:
            if let touch = touches.first {
                let location = touch.location(in: self)
                if bird.contains(location) {
                    print("You touched the bird")
                    panRecognizer.isEnabled = false
                    bird.grabbed = true
                    bird.position = location
                }
            }
        case .flying:
            print("flying state")
            break
        case .finished:
            print("finished state")
            guard let view = view else { return }
            let moveCameraBack = SKAction.move(to: CGPoint(x: view.frame.size.width/2, y: view.frame.size.height/2), duration: 2.0)
            moveCameraBack.timingMode = .easeInEaseOut
            
            gameCamera.run(moveCameraBack, completion: {
                print("move camera back completion" )
                self.panRecognizer.isEnabled = true
                self.addBird()
            })
        case .animating:
            print("animating")
            break
        }
        
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("::touchesMoved::")
        
        if let touch = touches.first {
            if(bird.grabbed) {
                let location = touch.location(in: self)
                bird.position = location
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("::touchesEnded::")
        
        if(bird.grabbed) {
            gameCamera.setConstraints(scene: self, frame: frame, node: bird)
            
            bird.grabbed = false
            panRecognizer.isEnabled = true
            bird.flying = true
            roundedState = .flying
            
            // determine force on bird as a function of how far away bird is from anchor point
            var dx = anchor.position.x - bird.position.x
            var dy = anchor.position.y - bird.position.y
            
            let impulse = CGVector(dx: dx, dy: dy)
            bird.physicsBody?.applyImpulse(impulse)
            bird.isUserInteractionEnabled = false
            
            constrainToAnchor(active: false)
        }
    }
    
    func setupLevel() {
        if let mapnode = childNode(withName: "Tile Map Node") as? SKTileMapNode {
            self.mapNode = mapnode
            maxScale = mapNode.mapSize.width/frame.size.width
        }
        addCamera()
        
        let physicsRect = CGRect(x: 0, y: mapNode.tileSize.height, width: mapNode.frame.size.width, height: mapNode.frame.size.height - mapNode.tileSize.height)
        physicsBody = SKPhysicsBody(edgeLoopFrom: physicsRect)
        physicsBody?.categoryBitMask = PhysicsCategories.edge
        physicsBody?.contactTestBitMask = PhysicsCategories.bird | PhysicsCategories.block
        physicsBody?.collisionBitMask = PhysicsCategories.all
        
        anchor.position = CGPoint(x: mapNode.frame.midX/2, y: mapNode.frame.midY/2)
        addChild(anchor)
        addBird()
    }
    
    func addBird() {
        if !birds.isEmpty {
            bird = birds.removeFirst()
        } else {
            print("No more birds")
            return
        }
        
        bird.position = anchor.position
        
        bird.physicsBody = SKPhysicsBody(rectangleOf: bird.size)
        bird.physicsBody?.isDynamic = false
        bird.physicsBody?.categoryBitMask = PhysicsCategories.bird
        bird.physicsBody?.contactTestBitMask = PhysicsCategories.all
        bird.physicsBody?.collisionBitMask = PhysicsCategories.block | PhysicsCategories.edge
        
        addChild(bird)
        roundedState = .ready
        
        constrainToAnchor(active: true)
    }
    
    func constrainToAnchor(active : Bool) {
        if active {
            let slingRange = SKRange(lowerLimit: 0.0, upperLimit: bird.size.width * 3)
            let positionConstraint = SKConstraint.distance(slingRange, to: anchor)
            
            bird.constraints = [positionConstraint]
        } else {
            bird.constraints?.removeAll()
        }
    }
    
    func setupGestureRecognizers() {
        guard let view = view else { return }
        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan))
        pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        view.addGestureRecognizer(panRecognizer)
        view.addGestureRecognizer(pinchRecognizer)
    }
    
    func addCamera() {
        guard let view = view else { return }
        gameCamera.position = CGPoint(x: view.bounds.size.width/2, y: view.bounds.size.height/2)
        camera = gameCamera
        
        gameCamera.setConstraints(scene: self, frame: mapNode.frame, node: nil)
        addChild(gameCamera)
    }
    
    override func didSimulatePhysics() {
        print("::didSimulatePhyisics::")
        guard let physicsBody = bird.physicsBody else { return }
        
        if physicsBody.isResting && roundedState == .flying {
            gameCamera.setConstraints(scene: self, frame: mapNode.frame, node: nil)
            bird.removeFromParent()
            roundedState = .finished
        }
    }
}

// all
extension GameScene {
    
    @objc func pan(sender : UIPanGestureRecognizer) {
        guard let view = view else { return }
        
        let translation = sender.translation(in: view) * gameCamera.yScale
        
        gameCamera.position = CGPoint(x: gameCamera.position.x - translation.x, y: gameCamera.position.y + translation.y)
        
        sender.setTranslation(CGPoint.zero, in: view)
    }
    
    @objc func pinch(sender : UIPinchGestureRecognizer) {
        if(sender.numberOfTouches == 2) {
            let locationInView = sender.location(in: view)
            let location = convertPoint(fromView: locationInView)
            
            if(sender.state == .changed) {
                let convertedScale = 1/sender.scale
                let newScale = gameCamera.yScale * convertedScale
                
                if (newScale < maxScale && newScale > 0.5) {
                    gameCamera.setScale(newScale)
                }
                
                let locationAfterScale = convertPoint(fromView: locationInView)
                let locationDelta = location - locationAfterScale
                let newPosition = locationDelta + gameCamera.position
                
                gameCamera.position = newPosition
                sender.scale = 1.0
                gameCamera.setConstraints(scene: self, frame: mapNode.frame, node: nil)
            }
        }
    }
    
}
