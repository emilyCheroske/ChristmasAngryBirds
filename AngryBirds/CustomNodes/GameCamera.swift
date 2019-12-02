//
//  GameCamera.swift
//  AngryBirds
//
//  Created by Emily Cheroske on 12/1/19.
//  Copyright © 2019 Emily Cheroske. All rights reserved.
//

import SpriteKit

class GameCamera: SKCameraNode {
    
    func setConstraints(scene : SKScene, frame : CGRect, node : SKNode?) {
        
        // specify contrants for the camera so that we don't see things not in our tileset
        let scaledSize = CGSize(width: scene.size.width * xScale, height: scene.size.height * yScale)
        let boardContentRect = frame
        
        // do not want to allow the camera to pass
        let xInset = min(scaledSize.width/2, boardContentRect.width/2)
        let yInset = min(scaledSize.height/2, boardContentRect.height/2)
        
        let insetContentRect = boardContentRect.insetBy(dx: xInset, dy: yInset)
        
        let xRange = SKRange(lowerLimit: insetContentRect.minX, upperLimit: insetContentRect.maxX)
        let yRange = SKRange(lowerLimit: insetContentRect.minY, upperLimit: insetContentRect.maxY)
        
        let levelEdge = SKConstraint.positionX(xRange, y: yRange)
        
        if let node = node {
            let zeroRange = SKRange(constantValue: 0.0)
            let constraint = SKConstraint.distance(zeroRange, to: node)
            
            constraints = [levelEdge, constraint]
        } else {
            constraints = [levelEdge]
        }
    }
}
