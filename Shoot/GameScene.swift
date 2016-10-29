//
//  GameScene.swift
//  Shoot
//
//  Created by Dylan on 8/12/15.
//  Copyright (c) 2015 DIG Productions. All rights reserved.
//

import SpriteKit
import CoreMotion

struct PhysicsCategory {
    static let None  : UInt32 = 0
    static let All   : UInt32 = UInt32.max
    static let UFO   : UInt32 = 0b1
    static let Bullet: UInt32 = 0b10
    static let Wall: UInt32 = 0b100
    static let Player: UInt32 = 0b1000
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //Constants
    let kPlayerName = "player"
    let kScoreHudName = "scoreHud"
    
    let kStarSpeedMultiple: CGFloat = 30.0
    
    //Star vars
    let lowerXBound: CGFloat = 0.0
    let lowerYBound: CGFloat = 0.0
    var higherXBound: CGFloat = 0.0
    var higherYBound: CGFloat = 0.0
    
    var starLayer: [[SKSpriteNode]] = []
    var starLayerSpeed: [CGFloat] = []
    var starLayerColor: [SKColor] = []
    var starLayerCount: [Int] = []
    
    //star scrolling
    var xDir: CGFloat = -1.0
    var yDir: CGFloat = 0.0
    
    //deltaTime for star field
    var lastUpdate: NSTimeInterval = 0
    //~1/60
    var deltaTime: CGFloat = 0.0166
    
    var calibrationZ = 0.0
    
    var contentCreated = false
    
    var calibrated = false
    
    var gameOver = false
    
    var score: Int = 0
    
    let motionManager: CMMotionManager = CMMotionManager()
    
    override func didMoveToView(view: SKView) {
        if (!contentCreated) {
            createContent()
            contentCreated = true
            
            motionManager.startDeviceMotionUpdates()
        }
    }
    
    func createContent() {
        backgroundColor = SKColor.blackColor()
        
        physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
        
        physicsBody!.categoryBitMask = PhysicsCategory.Wall
        
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
        
        createStars()
        
        setupPlayer()
        
        setupHud()
        
        addEnemies()
    }
    
    func createStars() {
        //Make sure stars head towards us
        xDir = -1.0
        yDir = 0.0
        
        higherXBound = self.frame.width
        higherYBound = self.frame.height
        
        //dummy sprite
        let dummySprite = SKSpriteNode(imageNamed: "star")
        
        //Star layers
        starLayer = [[dummySprite],[dummySprite],[dummySprite]]
        
        //layer 0
        starLayerCount.append(50)
        starLayerSpeed.append(3.0 * kStarSpeedMultiple)
        starLayerColor.append(SKColor.whiteColor())
        
        //layer 1
        starLayerCount.append(50)
        starLayerSpeed.append(2.0 * kStarSpeedMultiple)
        starLayerColor.append(SKColor.whiteColor())
        
        //layer 2
        starLayerCount.append(50)
        starLayerSpeed.append(1.0 * kStarSpeedMultiple)
        starLayerColor.append(SKColor.whiteColor())
        
        //Create the stars
        for starLayers in 0...(starLayer.count-1) {
            
            for _ in 1...starLayerCount[starLayers] {
                let starSprite = SKSpriteNode(imageNamed: "star")
                
                //Randomize star's position
                let xPos = CGFloat(Float(arc4random()) / Float(UINT32_MAX)) * higherXBound
                let yPos = CGFloat(Float(arc4random()) / Float(UINT32_MAX)) * higherYBound
                
                starSprite.position = CGPointMake(xPos, yPos)
                
                //Ensure the color is correct by blending it completely
                starSprite.colorBlendFactor = 1.0
                starSprite.color = starLayerColor[starLayers]
                
                starLayer[starLayers].append(starSprite)
                self.addChild(starSprite)
            }
        }
    }
    
    func addEnemies() {
        runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.runBlock(addUFO), SKAction.waitForDuration(5.0)])))
    }
    
    func setupPlayer() {
        let player = makePlayer()
        
        player.position = CGPoint(x: size.width*0.1, y: size.height*0.5)
        
        addChild(player)
    }
    
    func makePlayer() -> SKNode {
        let player = SKSpriteNode(imageNamed: "player")
        
        player.name = kPlayerName
        
        player.physicsBody = SKPhysicsBody(rectangleOfSize: player.frame.size)
        
        player.physicsBody?.dynamic = true
        
        player.physicsBody?.categoryBitMask = PhysicsCategory.Player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.UFO
        
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.mass = 0.02
        
        return player
    }
    
    func setupHud() {
        score = 0
        
        let scoreLabel = SKLabelNode(fontNamed: "Courier")
        scoreLabel.name = kScoreHudName
        scoreLabel.fontSize = 25
        scoreLabel.fontColor = SKColor.whiteColor()
        scoreLabel.text = String(format: "Score: %0u", score)
        
        scoreLabel.position = CGPoint(x: frame.size.width/2, y: size.height - (40 + scoreLabel.frame.size.height/2))
        addChild(scoreLabel)
        
    }
    
    func processUserMotionForUpdate(currentTime: CFTimeInterval) {
        if let player = childNodeWithName(kPlayerName) as! SKSpriteNode! {
            
            if let data = motionManager.deviceMotion {
                if !calibrated {
                    calibrationZ = data.gravity.z
                    
                    calibrated = true
                }
                
                //If there's accel > threshold
                if (fabs(data.gravity.z - calibrationZ) > 0.2) {
                    let accelZ = data.gravity.z * -1

                    let offset = calibrationZ * 20.0
                    
                    let movement = (accelZ * 20.0) + offset
                    
                    player.physicsBody!.applyForce(CGVectorMake(0, CGFloat(movement)))
                } else {
                    player.physicsBody!.applyForce(CGVectorMake(0, 0))
                }
            }
        }
    }
    
    func addToScore(points: Int) {
        self.score += points
        
        let scoreText = self.childNodeWithName(kScoreHudName) as! SKLabelNode
        
        scoreText.text = String(format: "Score: %0u", self.score)
    }
    
    func moveSingleStarLayer(starLayer: [SKSpriteNode], speed: CGFloat) {
        var starSprite: SKSpriteNode
        
        var newX: CGFloat = 0.0
        var newY: CGFloat = 0.0
        
        for index in 0...starLayer.count-1 {
            starSprite = starLayer[index]
            
            newX = starSprite.position.x + xDir * speed * deltaTime
            newY = starSprite.position.y + yDir * speed * deltaTime
            
            starSprite.position = boundFix(CGPointMake(newX, newY))
        }
    }
    
    func boundFix(pos: CGPoint) -> CGPoint {
        var x = pos.x
        var y = pos.y
        
        if x < 0 {
            x += higherXBound
        }
        
        if y < 0 {
            y += higherYBound
        }
        
        if x > higherXBound {
            x -= higherXBound
        }
        
        if y > higherYBound {
            y -= higherYBound
        }
        
        return CGPointMake(x, y)
    }
    
    override func update(currentTime: NSTimeInterval) {
        if !gameOver {
            processUserMotionForUpdate(currentTime)
            
            deltaTime = CGFloat(currentTime - lastUpdate)
            lastUpdate = currentTime
            
            if deltaTime > 1.0 {
                deltaTime = 0.0166
            }
            
            //Move starfield
            for index in 0...(starLayer.count-1) {
                moveSingleStarLayer(starLayer[index], speed: starLayerSpeed[index])
            }
        }
    }
    
    //Shooting bullets
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            let player = childNodeWithName(kPlayerName) as! SKSpriteNode
            
            let touchLocation = touch.locationInNode(self)
            
            let bullet = SKSpriteNode(imageNamed: "bullet")
            
            bullet.physicsBody = SKPhysicsBody(rectangleOfSize: bullet.size)
            bullet.physicsBody?.dynamic = true
            bullet.physicsBody?.categoryBitMask = PhysicsCategory.Bullet
            bullet.physicsBody?.contactTestBitMask = PhysicsCategory.UFO
            bullet.physicsBody?.collisionBitMask = PhysicsCategory.None
            bullet.physicsBody?.usesPreciseCollisionDetection = true
            
            bullet.position.x = player.position.x + player.size.width/2 + bullet.size.width/2
            
            bullet.position.y = player.position.y
            
            addChild(bullet)
            
            let actionMove = SKAction.moveToX(CGFloat(size.width + bullet.size.width), duration: 1.0)
            let actionMoveDone = SKAction.removeFromParent()
            
            bullet.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        }
        super.touchesEnded(touches, withEvent:event)
    }
    
    //UFO Stuff
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addUFO() {
        //Create UFO Sprite
        let ufo = SKSpriteNode(imageNamed: "ufo")
        
        ufo.physicsBody = SKPhysicsBody(rectangleOfSize: ufo.size) // 1
        ufo.physicsBody?.dynamic = true
        ufo.physicsBody?.categoryBitMask = PhysicsCategory.UFO
        ufo.physicsBody?.contactTestBitMask = PhysicsCategory.Bullet | PhysicsCategory.Player
        ufo.physicsBody?.collisionBitMask = PhysicsCategory.None
        
        //Random spawn on y axis
        let actualY = random(min: ufo.size.height/2, max: size.height - ufo.size.height/2)
        
        //Start slightly off screen
        ufo.position = CGPoint(x: size.width + ufo.size.width/2, y: actualY)
        
        addChild(ufo)
        
        //Determine speed
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        //Create actions
        let actionMove = SKAction.moveTo(CGPoint(x: -ufo.size.width/2, y: actualY), duration: NSTimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        
        let loseAction = SKAction.runBlock() {
            self.gameIsOver()
        }
        
        ufo.runAction(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if ((firstBody.categoryBitMask & PhysicsCategory.UFO != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Bullet != 0)) {
                bulletDidHitUFO(firstBody.node as! SKSpriteNode, bullet: secondBody.node as! SKSpriteNode)
        } else if ((firstBody.categoryBitMask & PhysicsCategory.UFO != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Player != 0)) {
                ufoDidHitPlayer(firstBody.node as! SKSpriteNode, player: secondBody.node as! SKSpriteNode)
        }
    }
    
    func bulletDidHitUFO(ufo:SKSpriteNode, bullet:SKSpriteNode) {
        print("Hit")
        bullet.removeFromParent()
        ufo.removeFromParent()
        
        addToScore(1)
    }
    
    func ufoDidHitPlayer(ufo: SKSpriteNode, player: SKSpriteNode) {
        print("Collision")
        ufo.removeFromParent()
        player.removeFromParent()
        
        gameIsOver()
    }
    
    func gameIsOver() {
        gameOver = true
        
        let reveal = SKTransition.flipHorizontalWithDuration(0.5)
        let gameOverScene = GameOverScene(size: self.size)
        self.view?.presentScene(gameOverScene, transition: reveal)
    }
}
