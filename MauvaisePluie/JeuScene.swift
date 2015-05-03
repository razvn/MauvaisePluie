//
//  JeuScene.swift
//  MauvaisePluie
//
//  Created by Razvan on 22/04/2015.
//  Copyright (c) 2015 Razvan.net. All rights reserved.
//

import SpriteKit

protocol JeuSceneProtocole {
    func animationStartBegin()
    func animationStartEnd()
    func animationFinishStart()
    func animationFinishEnd()
    func getScore()->Int
    func incrementScore()->Int
}


class JeuScene: SKScene, SKPhysicsContactDelegate {
    var dataSource : MauvaisePluieDataSource!
    var delegateViewController: JeuSceneProtocole?
    
    private let player = SKSpriteNode(imageNamed: "player")
    private var bgImage: SKSpriteNode!
    
    
    private var  label = SKLabelNode(fontNamed: "Chalkduster")
    
    private var labelNiveau = SKLabelNode(fontNamed: "Chalkduster")
    private var labelScore = SKLabelNode(fontNamed: "Chalkduster")
    private var labelTextScore = SKLabelNode(fontNamed: "Chalkduster")
    
    private var countDownValue = 3
    
    private var startAnimationEnded = false
    
    private var asteroidId = 0
    private var asteroidsOnScreen = 0
    private var probabilityToCreateNew = 0
    
    private var maxAsteroidesOnScreen = 0
    private var niveauJeu = 0
    private var isPhone = false
    
    private var burstNode: SKEmitterNode?
    
    private struct Constants {
        static let PlayerWidth:CGFloat = 40.0
        static let PlayerMoveTime: CGFloat = 2.0 //seconds - time to move the player across the screen from left border to right one
        static let ParamMaxPhone = 20
        static let ParamMaxPad = 50
        static let ParamMaxFactor = 10
        static let LimitRandomApparition = 20 //Probability limit to create a new Asteroid
    }
    
    private struct Actions {
        static let PlayerMove = "PlayerMove"
        
    }
    
    private struct PhysicsCategory {
        static let None: UInt32 = 0
        static let All: UInt32 = UInt32.max
        static let Asteroid: UInt32 = 0b1 //1
        static let Player: UInt32 = 0b10 //2
    }
    
    
    ///view initialisation
    override func didMoveToView(view: SKView) {
        
        delegateViewController?.animationStartBegin()
        backgroundColor = SKColor.blackColor()
        
        niveauJeu = dataSource.getNiveauEncours().valeur
        
        var nb = 0
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            isPhone = false
            nb = Constants.ParamMaxPad
        } else {
            nb = Constants.ParamMaxPhone
            isPhone = true
        }
        
        maxAsteroidesOnScreen = nb + Constants.ParamMaxFactor * niveauJeu
        
        let ratio:CGFloat = player.size.width / player.size.height
        let height = Constants.PlayerWidth / ratio
        
        player.size = CGSize(width: Constants.PlayerWidth , height: height)
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: fmin(Constants.PlayerWidth, height) / 2.0)
        player.physicsBody?.dynamic = true
        player.physicsBody?.categoryBitMask = PhysicsCategory.Player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.Asteroid
        player.physicsBody?.collisionBitMask = PhysicsCategory.None //todo see what happens when activate collision bewen player & asteroid
        player.physicsBody?.usesPreciseCollisionDetection = true
        
        var startAnimationDuration = 3.0
        var delta = CGVector(dx: 0, dy: 0)
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            let ymove = bgImage.size.height / 7
            delta = CGVector(dx: 0, dy: -ymove)
        }
        let actionMoveBackground = SKAction.moveBy(delta, duration: startAnimationDuration)
        runAction(SKAction.playSoundFileNamed("sw.m4a", waitForCompletion: false))
        bgImage.runAction(actionMoveBackground)
        
        //add physics
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
        
        println("Player.size: \(player.size) - size.height: \(size.height)")
        player.position = CGPoint(x: size.width / 2, y: -height / 2)
        
        addChild(player)
        
        let actionMovePlayer = SKAction.moveTo(CGPoint(x: size.width / 2, y: height / 2), duration: startAnimationDuration)
        player.runAction(actionMovePlayer, completion: { () -> Void in
            self.startAnimationEnded = true
            self.delegateViewController?.animationStartEnd()
            self.labelNiveau.hidden = false
            self.labelScore.hidden = false
            self.labelTextScore.hidden = false
        })
        
        label.fontSize = 30
        label.fontColor = SKColor.redColor()
        label.text = "\(countDownValue)"
        label.position = CGPoint(x: size.width/2,y: size.height/2)
        addChild(label)
        
        labelNiveau.fontSize = 16
        labelNiveau.fontColor = SKColor.whiteColor()
        labelNiveau.text = dataSource.getNiveauEncours().nom
        labelNiveau.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left;
        labelNiveau.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Top
        labelNiveau.position = CGPoint(x: 10, y: size.height-10)
        labelNiveau.hidden = true
        addChild(labelNiveau)
        
        labelTextScore.fontSize = 16
        labelTextScore.fontColor = SKColor.whiteColor()
        labelTextScore.text = "Score"
        labelTextScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left;
        labelTextScore.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Top
        labelTextScore.position = CGPoint(x:size.width - 120, y: size.height-10)
        labelTextScore.hidden = true
        addChild(labelTextScore)

        
        labelScore.fontSize = 16
        labelScore.fontColor = SKColor.whiteColor()
        labelScore.text = "\(delegateViewController!.getScore())"
        labelScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right;
        labelScore.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Top
        labelScore.position = CGPoint(x: size.width-10, y: size.height-10)
        labelScore.hidden = true
        addChild(labelScore)
        
        let actionCountDown = SKAction.waitForDuration(1.0)
        let actionPerform = SKAction.runBlock { () -> Void in
            self.countDown()
        }
        
        //run countdown
        label.runAction(SKAction.repeatAction(SKAction.sequence([actionCountDown, actionPerform]), count: 4), completion: { () -> Void in
            self.label.removeFromParent()
            self.startGame()
        })
    }
    
    ///stat game adding asteroids animation
    private func startGame() {
        //todo manage speed aparation
        let durationWait = 0.2
        self.runAction(SKAction.repeatActionForever(
            SKAction.sequence([
                SKAction.runBlock(self.addAsteroid),
                SKAction.waitForDuration(durationWait)
                ])
            ))
        
    }
    
    ///countdown and update label value
    private func countDown() {
        if (countDownValue > 1) {
            countDownValue--
            label.text = "\(countDownValue)"
        } else {
            label.text = "Go"
        }
    }
    
    
    ///collision asteroid player handle
    private func asteroidDidCollideWithPlayer(asteroid: SKSpriteNode, player: SKSpriteNode) {
        println("Touché")
        delegateViewController?.animationFinishStart()
        labelNiveau.hidden = true
        labelScore.hidden = true
        labelTextScore.hidden = true
        
        self.removeAllActions()
        player.removeAllActions()
        
        let target_x = player.position.x
        let target_y = player.position.y

        label.text = "Arghhhhhhh!!!"
        addChild(label)
        runAction(SKAction.playSoundFileNamed("Explosion.mp3", waitForCompletion: false))
        if burstNode != nil {
            burstNode!.position = CGPointMake(target_x, target_y)
            player.removeFromParent()
            self.addChild(burstNode!)
        }
        
        
        var delta = CGVector(dx: 0, dy: 0)
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            let ymove = bgImage.size.height / 7
            let delta = CGVector(dx: 0, dy: ymove)
        }
        let actionMoveBackground = SKAction.moveBy(delta, duration: 3.0)
        runAction(SKAction.playSoundFileNamed("sw.m4a", waitForCompletion: false))
        bgImage.runAction(actionMoveBackground, completion: { () -> Void in
            self.delegateViewController?.animationFinishEnd()
        })

    }
    
    ///stop all actions and remove all childrens
    func stopAll() {
        self.removeAllActions()
        self.removeAllChildren()
    }
    
    
    //Mark: - SKPhysicsContactDelegate
    ///contact interception
    func didBeginContact(contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.contactTestBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        //
        if ((firstBody.categoryBitMask & PhysicsCategory.Asteroid != 0) && (secondBody.categoryBitMask & PhysicsCategory.Player != 0)) {
            asteroidDidCollideWithPlayer(firstBody.node as! SKSpriteNode, player: secondBody.node as! SKSpriteNode)
        }
    }
    
    
    ///move right player
    func movePlayerRight() {
        //we don't move till animation does not end
        if (startAnimationEnded) {
            stopPlayer()
            
            let distance = size.width - player.position.x
            let duration = NSTimeInterval(distance * Constants.PlayerMoveTime / size.width)
            
            let maxX = size.width - player.size.width / 2
            
            let actionMove = SKAction.moveTo(CGPoint(x: maxX, y:player.size.height / 2.0), duration: duration)
            //let actionMoveStop = SKAction.removeFromParent()
            player.runAction(SKAction.sequence([actionMove]), withKey: Actions.PlayerMove)
        }
    }
    
    
    ///move left player
    func movePlayerLeft() {
        //we don't move till animation does not end
        if (startAnimationEnded) {
            stopPlayer()
        
            let duration = NSTimeInterval(player.position.x * Constants.PlayerMoveTime / size.width)
        
            let minX = player.size.width / 2
    
            let actionMove = SKAction.moveTo(CGPoint(x: minX, y:player.size.height / 2.0), duration: duration)
            //let actionMoveStop = SKAction.removeFromParent()
            player.runAction(SKAction.sequence([actionMove]), withKey: Actions.PlayerMove)
        }
    }
    
    
    ///stop player movements
    func stopPlayer() {
        if (startAnimationEnded) {
            //if player is already moving
            if player.actionForKey(Actions.PlayerMove) != nil {
                player.removeActionForKey(Actions.PlayerMove)
            }
        }
    }
    
    private func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    private func random(#min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    
    ///decide if create a new asteroid or not
    private func createNewAsteroid() -> Bool {
        if asteroidsOnScreen < maxAsteroidesOnScreen {
            let p = random(min:0, max:100) - CGFloat(probabilityToCreateNew) - 10 * (CGFloat(niveauJeu) - 1)
            println("asteroidsOnScreen: \(asteroidsOnScreen) - probabilityToCreateNew: \(probabilityToCreateNew) - p: \(p) - maxAsteroidesOnScreen: \(maxAsteroidesOnScreen) - LimitRandomApparition: \(Constants.LimitRandomApparition)")
            return p < CGFloat(Constants.LimitRandomApparition)
            
        }
        return false
    }
    
    
    //add a new asteroid to the scene
    private func addAsteroid() {
        //should create a new asteroid?
        var createNew = createNewAsteroid()
        
        //Create Sprite
        if createNew {
            if  let img = dataSource.getUnAsteroide() {
                let asteroide = SKSpriteNode(imageNamed: img)
                asteroidId++
                asteroide.name = "id: \(asteroidId)"
                asteroide.physicsBody = SKPhysicsBody(circleOfRadius: asteroide.size.width / 2)
                asteroide.physicsBody?.dynamic = true
                asteroide.physicsBody?.categoryBitMask = PhysicsCategory.Asteroid
                asteroide.physicsBody?.contactTestBitMask = PhysicsCategory.Player //contat to notify lister
                asteroide.physicsBody?.collisionBitMask = PhysicsCategory.Asteroid //collision to handle
                asteroide.physicsBody?.usesPreciseCollisionDetection = true
                asteroide.physicsBody?.restitution = 1.0
                asteroide.physicsBody?.friction = 0.0
                asteroide.physicsBody?.linearDamping = 0.0
                asteroide.physicsBody?.angularDamping = 0.0
                    
                asteroide.physicsBody?.mass = random(min: 50, max:100)
                
                let actualX = random(min: asteroide.size.width, max: size.width - asteroide.size.width)
                
                //position the aseroie slightly off screen up
                let actualY = size.height + asteroide.size.height / 2
                asteroide.position = CGPoint(x: actualX, y: actualY)
                
                //add asteroide
                addChild(asteroide)
                
                asteroidsOnScreen++
                probabilityToCreateNew = 0
                
                //Speed of the asteroide
                //todo constants & change in function of level
                let level1Min = 3.5
                let levelStepMinMax = 1.5
                let levelFactor = 0.5
                
                let levelMin = level1Min - (levelFactor * (Double(niveauJeu) - 1))
                let levelMax = levelMin + 2
                var actualDuration = random(min: CGFloat(levelMin), max: CGFloat(levelMax))
                
                //create actions
                //todo change X to a random deviation
                let xDeviationConst:CGFloat = 0.5
                let xdeviation = random(min: -xDeviationConst * size.height, max: xDeviationConst * size.height)
                var destinationX = actualX + xdeviation
                var destinationY = -asteroide.size.height/2
                
                println("\(asteroide.name!): xfrom: \(actualX) - yfrom: \(actualY) - xto: \(destinationX) - yto: \(destinationY) - duration: \(actualDuration)")

                //lets see if it goes out on the side left side, no need to let it go to the buttom so make it disapear once they're out of screen on x
                if destinationX < -asteroide.size.width/2  {
                    
                    //calculate it using thales
                    
                    //normal big triangle
                    //  Y side = start Y position + abs(finish Y position)
                    let bigY = actualY + fabs(destinationY)
                    //  X side = abs(finish Y position) + actual X Position
                    let bigX = fabs(destinationX) + actualX
                    
                    //small tirangle
                    //  x side is abs(destination) - asteroide.size/2
                    let xSide = fabs(destinationX) - asteroide.size.width/2

                    //  using thales we calcylate de y side as big Y * small X / big X and for gettign the value from 0 remove abs(destinationY) -> in fact it si asteroid.size/2
                    let ySide = bigY * xSide / bigX - fabs(destinationY)
                    
                    println("* \(asteroide.name!) * LEFT: bigY: \(bigY) - bigX: \(bigX) - xSide:\(xSide) - ySide:\(ySide)")
                    
                    destinationY = ySide
                    destinationX = -asteroide.size.width/2
                    println("\(asteroide.name!): changed destination - xto: \(destinationX) - yto: \(destinationY)")
                    
                } else if (destinationX - size.width) > asteroide.size.width/2 { //goes out from left side
                    
                    //normal big triangle
                    //  Y side = start Y position + abs(finish Y position)
                    let bigY = actualY + fabs(destinationY)
                    //  X side = finish Y position) - actual X Position
                    let bigX = destinationX - actualX

                    //small tirangle
                    //  x side is X destination - screen width - asteroide.size/2
                    let xSide = destinationX - size.width - asteroide.size.width/2
                    
                    //  using thales we calculate de y side as big Y * small X / big X and for gettign the value from 0 remove abs(destinationY) -> in fact it is asteroid.size/2
                    let ySide = bigY * xSide / bigX - fabs(destinationY)
                    
                    println("*\(asteroide.name!)* RIGHT: bigY: \(bigY) - bigX: \(bigX) - xSide:\(xSide) - ySide:\(ySide)")
                    
                    destinationY = ySide
                    destinationX = size.width + asteroide.size.width/2
                    println("\(asteroide.name!): changed destination - xto: \(destinationX) - yto: \(destinationY)")
                }
                
                let actionMove = SKAction.moveTo(CGPoint(x: destinationX, y: destinationY), duration: NSTimeInterval(actualDuration))
                let actionMoveDone = SKAction.removeFromParent()
                
                let actionMoveScore = SKAction.runBlock({ () -> Void in
                    if (asteroide.frame.maxX > 0 && asteroide.frame.minX < self.size.width && asteroide.position.y < 0) {
                        let int = self.delegateViewController!.incrementScore()
                        self.labelScore.text = "\(int)" //String(format: "Score %5d", int)
                        println("\(asteroide.name!) - Score++")
                    }
                    self.asteroidsOnScreen--
                })

                //todo tweek
                let angle = random(min: CGFloat(M_PI) / 4, max: CGFloat(M_PI) / 2)
                let duration = random(min: CGFloat(1.0), max: CGFloat(2.0))
                //todo duration tweek
                let rotationMove = SKAction.rotateByAngle(angle, duration: NSTimeInterval(duration))
                let repeatRotation = SKAction.repeatActionForever(rotationMove)
                //asteroide.anchorPoint = CGPointZero
                asteroide.runAction(repeatRotation)
                asteroide.runAction(SKAction.sequence([actionMove,  actionMoveScore, actionMoveDone]))
                
            }
        } else {
            probabilityToCreateNew++
        }
    }
    
    
    
    override init(size: CGSize) {
        super.init(size: size)
        bgImage = SKSpriteNode(imageNamed: "fond-mauvaise-pluie")
        
        self.addChild(bgImage)
        bgImage.position = CGPointMake(self.size.width / 2, self.size.height / 2)
        
        if let burstPath = NSBundle.mainBundle().pathForResource("PlayerParticle", ofType: "sks") {
            burstNode = NSKeyedUnarchiver.unarchiveObjectWithFile(burstPath) as? SKEmitterNode
        }
        
     
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}
