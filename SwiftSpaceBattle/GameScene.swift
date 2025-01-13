//
//  GameScene.swift
//  SwiftSpaceBattle
//
//  Created by Luis Enrique Rosas Espinoza on 12/01/25.
//

import SwiftUI
import SpriteKit
import GameplayKit

final class GameScene: SKScene, SKPhysicsContactDelegate {
    var score: Int = 0
    let scoreLabel = SKLabelNode(fontNamed: "Arial")
    
    let type = GKRandomDistribution(forDieWithSideCount: 2)
    var timerEnemy: Timer?
    
    static func newGame() -> GameScene {
        guard let game = GameScene(fileNamed: "GameScene") else {
            fatalError("GameScene not found")
        }
        
        game.scaleMode = .aspectFill
        return game
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        if bodyA.categoryBitMask == PhysicsCategory.laser && bodyB.categoryBitMask == PhysicsCategory.enemy {
            bodyA.node?.removeFromParent()
            bodyB.node?.removeFromParent()
            
            score += 10
            scoreLabel.text = "Score: \(score)"
        }
        
        if bodyA.categoryBitMask == PhysicsCategory.ship && bodyB.categoryBitMask == PhysicsCategory.enemy {
            bodyA.node?.removeFromParent()
            bodyB.node?.removeFromParent()
            
            NotificationCenter.default.post(
                name: .gameOver,
                object: nil,
                userInfo: ["score": score]
            )
        }
    }
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero
        
        setupShip()
        
        scoreLabel.text = "Score: \(score)"
        scoreLabel.fontSize = 42
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 50)
        scoreLabel.zPosition = 10
        addChild(scoreLabel)
        
        let enemyLayer = SKNode()
        enemyLayer.name = "enemyLayer"
        addChild(enemyLayer)
        
        timerEnemy = Timer.scheduledTimer(withTimeInterval: .random(in: 2...4), repeats: true) { [weak self] _ in
            self?.spawnEnemy()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        moveScroll(layer: 0, scrollSpeed: 50)
        moveScroll(layer: 1, scrollSpeed: 70)
        moveScroll(layer: 2, scrollSpeed: 100)
    }
    
    func setupShip() {
        guard let ship = childNode(withName: "ship") as? SKSpriteNode else { return }
        let xRange = SKRange(lowerLimit: -(frame.width / 2) + ship.frame.width, upperLimit: (frame.width / 2) - ship.frame.width)
        let yRange = SKRange(lowerLimit: -(frame.height / 2) + 100, upperLimit: (frame.height / 4))
        
        let constraint = SKConstraint.positionX(xRange, y: yRange)
        ship.constraints = [constraint]
        
        ship.physicsBody = SKPhysicsBody(circleOfRadius: ship.size.width / 2)
        ship.physicsBody?.isDynamic = true
        ship.physicsBody?.categoryBitMask = PhysicsCategory.ship
        ship.physicsBody?.collisionBitMask = PhysicsCategory.none
        ship.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
    }
    
    func fireLasers() {
        guard let ship = childNode(withName: "ship") as? SKSpriteNode else { return }
        
        let laser = SKShapeNode(rectOf: CGSize(width: 3, height: 30))
        laser.fillColor = .white
        laser.strokeColor = .clear
        laser.blendMode = .add
        laser.zPosition = ship.zPosition - 1
        
        laser.position = CGPoint(x: ship.position.x, y: ship.position.y + ship.size.height / 2)
        
        addChild(laser)
        
        laser.physicsBody = SKPhysicsBody(rectangleOf: laser.frame.size)
        laser.physicsBody?.isDynamic = true
        laser.physicsBody?.categoryBitMask = PhysicsCategory.laser
        laser.physicsBody?.collisionBitMask = PhysicsCategory.none
        laser.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        
        let move = SKAction.moveTo(y: frame.height + laser.frame.height, duration: 2)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([move, remove])
        
        laser.run(sequence)
    }
    
    func moveScroll(layer: Int, scrollSpeed: CGFloat) {
        guard let background0_0 = childNode(withName: "background\(layer)-0") as? SKSpriteNode else { return }
        guard let background0_1 = childNode(withName: "background\(layer)-1") as? SKSpriteNode else { return }
        
        let deltaTime = CGFloat(1.0 / 60.0)
        
        background0_0.position.y -= scrollSpeed * deltaTime
        background0_1.position.y -= scrollSpeed * deltaTime
        
        if background0_0.position.y <= -background0_0.size.height {
            background0_0.position.y = background0_1.position.y + background0_1.size.height
        }
        
        if background0_1.position.y <= -background0_1.size.height {
            background0_1.position.y = background0_0.position.y + background0_0.size.height
        }
        
    }
    
    func spawnEnemy() {
        guard let enemyLayer = childNode(withName: "enemyLayer") else { return }
        guard let ship = childNode(withName: "ship") as? SKSpriteNode else { return }
        
        let enemyType = type.nextInt()
        let enemy = SKSpriteNode(imageNamed: "enemy\(enemyType)")
        
        enemy.size = ship.size * CGFloat.random(in: 0.5...0.8)
        
        enemy.zPosition = ship.zPosition
        
        enemy.position = CGPoint(x: .random(in: -frame.width / 2 ... frame.width / 2),
                                 y: frame.height / 2 + 50)
        
        enemyLayer.addChild(enemy)
        
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemy.size.width / 2)
        enemy.physicsBody?.isDynamic = true
        enemy.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        enemy.physicsBody?.collisionBitMask = PhysicsCategory.none
        enemy.physicsBody?.contactTestBitMask = PhysicsCategory.ship | PhysicsCategory.laser
        
        let amplitude: CGFloat = .random(in: 75...125)
        let frequency: CGFloat = .random(in: 2...3)
        let duration: TimeInterval = .random(in: 3...6)
        
        let path = CGMutablePath()
        let startX = enemy.position.x
        let startY = enemy.position.y
        path.move(to: CGPoint(x: startX, y: startY))
        
        for i in 0..<Int(frequency * 100) {
            let x = startX + amplitude * sin(CGFloat(i) * .pi / 50)
            let y = startY - CGFloat(i) * ((frame.height + (enemy.size.height * 2)) / (frequency * 100))
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        let waveAction = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration)
        let sequence = SKAction.sequence([waveAction, .removeFromParent()])
        
        enemy.run(sequence)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let _ = touches.first else { return }
        fireLasers()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard let ship = childNode(withName: "ship") as? SKSpriteNode else { return }
        
        let currentLocation = touch.location(in: self)
        let previousLocation = touch.previousLocation(in: self)
        
        let deltaX = currentLocation.x - previousLocation.x
        let deltaY = currentLocation.y - previousLocation.y
        
        let acceleration: CGFloat = 1.0
        
        ship.position.x += deltaX * acceleration
        ship.position.y += deltaY * acceleration
    }
}

extension CGSize {
    static func *= (lhs: inout CGSize, rhs: CGFloat) {
        lhs = CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
}

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let laser: UInt32 = 0b1
    static let enemy: UInt32 = 0b10
    static let ship: UInt32 = 0b100
}

extension Notification.Name {
    static let gameOver = Notification.Name("GAMEOVER")
}
