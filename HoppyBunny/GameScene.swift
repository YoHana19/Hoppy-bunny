//
//  GameScene.swift
//  HoppyBunny
//
//  Created by yo hanashima on 2017/05/23.
//  Copyright © 2017年 yo hanashima. All rights reserved.
//

import SpriteKit
import GameplayKit

enum GameSceneState {
    case Active, GameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var hero: SKSpriteNode!
    var scrollLayer: SKNode!
    var obstacleLayer: SKNode!
    var sphereLayer: SKNode!
    var cloudLayer: SKNode!
    var obstacleSource: SKNode!
    var sphereSource: SKNode!
    
    /* UI Connections */
    var buttonRestart: MSButtonNode!
    var scoreLabel: SKLabelNode!
    
    var sinceTouch : CFTimeInterval = 0
    var spawnTimer: CFTimeInterval = 0
    var spawnModified: CFTimeInterval = 1.5
    var spawnTimerSphere: CFTimeInterval = 0
    
    let fixedDelta: CFTimeInterval = 1.0/60.0 /* 60 FPS */
    var scrollSpeed: CGFloat = 160
    let scrollCloudSpeed: CGFloat = 200
    
    /* Game management */
    var gameState: GameSceneState = .Active
    
    var points = 0
    
    override func didMove(to view: SKView) {
        /* Set up your scene here */
        
        /* Recursive node search for 'hero' (child of referenced node) */
        hero = self.childNode(withName: "//savior") as! SKSpriteNode
        
        /* Set reference to scroll layer node */
        scrollLayer = self.childNode(withName: "scrollLayer")
        
        /* Set reference to cloud layer node */
        cloudLayer = self.childNode(withName: "cloudLayer")
        
        /* Set reference to obstacle layer node */
        obstacleLayer = self.childNode(withName: "obstacleLayer")

        /* Set reference to obstacle layer node */
        sphereLayer = self.childNode(withName: "sphereLayer")
        
        /* Set reference to obstacle Source node */
        obstacleSource = self.childNode(withName: "obstacle")
        
        /* Set reference to cube Source node */
        sphereSource = self.childNode(withName: "sphere")
        
        /* Set physics contact delegate */
        physicsWorld.contactDelegate = self
        
        /* Set UI connections */
        buttonRestart = self.childNode(withName: "buttonRestart") as! MSButtonNode
        
        /* Setup restart button selection handler */
        buttonRestart.selectedHandler = {
            
            /* Grab reference to our SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load Game scene */
            let scene = GameScene(fileNamed:"GameScene") as GameScene!
            
            /* Ensure correct aspect mode */
            scene!.scaleMode = .aspectFill
            
            /* Restart game scene */
            skView!.presentScene(scene)
            
        }
        
        /* Hide restart button */
        buttonRestart.state = .Hidden
        
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        
        /* Reset Score label */
        scoreLabel.text = String(points)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        /* Disable touch if game state is not active */
        if gameState != .Active { return }
        
        /* Called when a touch begins */
        
        /* Reset velocity, helps improve response against cumulative falling velocity */
        hero.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        
        /* Apply vertical impulse */
        hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 250))
        
        /* Apply subtle rotation */
        hero.physicsBody?.applyAngularImpulse(1)
        
        /* Reset touch timer */
        sinceTouch = 0
        
        /* Play SFX */
        let flapSFX = SKAction.playSoundFileNamed("SFX/sfx_flap", waitForCompletion: false)
        self.run(flapSFX)
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        /* Skip game update if game no longer active */
        if gameState != .Active { return }
        
        /* Called before each frame is rendered */
        
        /* Grab current velocity */
        let velocityY = hero.physicsBody?.velocity.dy ?? 0
        
        /* Check and cap vertical velocity */
        if velocityY > 400 {
            hero.physicsBody?.velocity.dy = 400
        }
        
        /* Apply falling rotation */
        if sinceTouch > 0.1 {
            let impulse = -20000 * fixedDelta
            hero.physicsBody?.applyAngularImpulse(CGFloat(impulse))
        }
        
        /* Clamp rotation */
        hero.zRotation.clamp(v1: CGFloat(-80).degreesToRadians(), CGFloat(30).degreesToRadians())
        hero.physicsBody?.angularVelocity.clamp(v1: -7, 7)
        
        /* Update last touch timer */
        sinceTouch+=fixedDelta
        
        /* Update last touch timer */
        scrollSpeed+=0.1
        
        /* Update spawntimer */
        spawnModified-=0.0001
        
        /* Process world scrolling */
        scrollWorld()
        
        /* Process cloud scrolling */
        scrollCloud()
        
        /* Process obstacles */
        updateObstacles()
        
        /* Process shperes */
        updateSpheres()

    }
    
    func scrollWorld() {
        /* Scroll World */
        scrollLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through scroll layer nodes */
        for ground in scrollLayer.children as! [SKSpriteNode] {
            
            /* Get ground node position, convert node position to scene space */
            let groundPosition = scrollLayer.convert(ground.position, to: self)
            
            /* Check if ground sprite has left the scene */
            if groundPosition.x <= -ground.size.width / 2 {
                
                /* Reposition ground sprite to the second starting position */
                let newPosition = CGPoint(x: (self.size.width / 2) + ground.size.width, y: groundPosition.y)
                
                /* Convert new node position back to scroll layer space */
                ground.position = self.convert(newPosition, to: scrollLayer)
            }
        }
    }
    
    func scrollCloud() {
        /* Scroll Cloud */
        cloudLayer.position.x -= scrollCloudSpeed * CGFloat(fixedDelta)
        
        /* Loop through scroll layer nodes */
        for cloud in cloudLayer.children as! [SKSpriteNode] {
            
            /* Get ground node position, convert node position to scene space */
            let cloudPosition = cloudLayer.convert(cloud.position, to: self)
            
            /* Check if ground sprite has left the scene */
            if cloudPosition.x <= -cloud.size.width / 2 {
                
                /* Reposition ground sprite to the second starting position */
                let newPosition = CGPoint(x: (self.size.width / 2) + cloud.size.width, y: cloudPosition.y)
                
                /* Convert new node position back to scroll layer space */
                cloud.position = self.convert(newPosition, to: cloudLayer)
            }
        }
    }
    
    func updateObstacles() {
        /* Update Obstacles */
        
        obstacleLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through obstacle layer nodes */
        for obstacle in obstacleLayer.children as! [SKReferenceNode] {
            
            /* Get obstacle node position, convert node position to scene space */
            let obstaclePosition = obstacleLayer.convert(obstacle.position, to: self)
            
            /* Check if obstacle has left the scene */
            if obstaclePosition.x <= 0 {
                
                /* Remove obstacle node from obstacle layer */
                obstacle.removeFromParent()
            }
            
        }
        
        /* Time to add a new obstacle? */
        if spawnTimer >= spawnModified {
            
            /* Create a new obstacle reference object using our obstacle resource */
            let newObstacle = obstacleSource.copy() as! SKNode
            obstacleLayer.addChild(newObstacle)
            
            /* Generate new obstacle position, start just outside screen and with a random y value */
            let randomPosition = CGPoint(x: 352, y: CGFloat.random(min: 234, max: 382))
            
            /* Convert new node position back to obstacle layer space */
            newObstacle.position = self.convert(randomPosition, to: obstacleLayer)
            
            // Reset spawn timer
            spawnTimer = 0
        }
        
        spawnTimer += fixedDelta
        
    }
    
    func updateSpheres() {
        /* Update Spheres */
        
        sphereLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through obstacle layer nodes */
        for sphere in sphereLayer.children as! [SKReferenceNode] {
            
            /* Get obstacle node position, convert node position to scene space */
            let spherePosition = sphereLayer.convert(sphere.position, to: self)
            
            /* Check if obstacle has left the scene */
            if spherePosition.x <= 0 {
                
                /* Remove obstacle node from obstacle layer */
                sphere.removeFromParent()
            }
            
        }
        
        /* Time to add a new obstacle? */
        if spawnTimerSphere >= 2.0 {
            
            /* Create a new obstacle reference object using our obstacle resource */
            let newObstacle = sphereSource.copy() as! SKNode
            sphereLayer.addChild(newObstacle)
            
            /* Generate new obstacle position, start just outside screen and with a random y value */
            let randomPosition = CGPoint(x: 400, y: CGFloat.random(min: 150, max: 450))
            
            /* Convert new node position back to obstacle layer space */
            newObstacle.position = self.convert(randomPosition, to: sphereLayer)
            
            // Reset spawn timer
            spawnTimerSphere = 0
        }
        
        spawnTimerSphere += fixedDelta
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        /* Ensure only called while game running */
        if gameState != .Active { return }
        
        /* Get references to bodies involved in collision */
        let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        
        /* Get references to the physics body parent nodes */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        /* Did our hero pass through the 'goal'? */
        if nodeA.name == "goal" || nodeB.name == "goal" {
            
            /* Increment points */
            points += 1
            
            /* Update score label */
            scoreLabel.text = String(points)
            
            /* Play SFX */
            let goalSFX = SKAction.playSoundFileNamed("SFX/sfx_goal", waitForCompletion: false)
            self.run(goalSFX)
            
            /* We can return now */
            return
        }
        
        /* Did our hero hit the 'sphere'? */
        if contactA.categoryBitMask == 16 || contactB.categoryBitMask == 16 {
            
            /* Increment points */
            points += 1
            
            /* Update score label */
            scoreLabel.text = String(points)
            
            /* Play SFX */
            let goalSFX = SKAction.playSoundFileNamed("SFX/sfx_goal", waitForCompletion: false)
            self.run(goalSFX)
            
            if contactA.categoryBitMask == 16 { removeSphere(node: nodeA) }
            if contactB.categoryBitMask == 16 { removeSphere(node: nodeB) }
            
            /* We can return now */
            return
        }
        
        /* Hero touches anything, game over */
        
        /* Change game state to game over */
        gameState = .GameOver
        
        /* Stop any new angular velocity being applied */
        hero.physicsBody?.allowsRotation = false
        
        /* Reset angular velocity */
        hero.physicsBody?.angularVelocity = 0
        
        /* Stop hero flapping animation */
        hero.removeAllActions()
        
        /* Create our hero death action */
        let heroDeath = SKAction.run({
            
            /* Put our hero face down in the dirt */
            self.hero.zRotation = CGFloat(-90).degreesToRadians()
            /* Stop hero from colliding with anything else */
            self.hero.physicsBody?.collisionBitMask = 0
        })
        
        /* Run action */
        hero.run(heroDeath)
        
        /* Load the shake action resource */
        let shakeScene:SKAction = SKAction.init(named: "Shake")!
        
        /* Loop through all nodes  */
        for node in self.children {
            
            /* Apply effect each ground node */
            node.run(shakeScene)
        }
        
        /* Show restart button */
        buttonRestart.state = .Active
    }
    
    func removeSphere(node: SKNode) {
        
        let sphereHit = SKAction.run({
            /* Remove seal node from scene */
            node.removeFromParent()
        })
        self.run(sphereHit)
    }
}
