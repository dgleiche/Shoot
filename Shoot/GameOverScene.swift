//
//  GameOverScene.swift
//  Shoot
//
//  Created by Dylan on 8/14/15.
//  Copyright (c) 2015 DIG Productions. All rights reserved.
//

import Foundation
import SpriteKit

class GameOverScene: SKScene {
    
    override init(size: CGSize) {
        super.init(size: size)
        
        backgroundColor = SKColor.blackColor()
        
        let message = "Game Over"
        
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = message
        label.fontSize = 40
        label.fontColor = SKColor.whiteColor()
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        runAction(SKAction.sequence([
            SKAction.runBlock() {
                let reveal = SKTransition.flipHorizontalWithDuration(0.5)
                let scene = GameScene(size: self.size)
                self.view?.presentScene(scene, transition:reveal)
            }
            ]))
    }
    
}