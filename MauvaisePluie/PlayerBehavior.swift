//
//  PlayerBehavior.swift
//  MauvaisePluie
//  Behaviour for the player (multiple ones)
//
//  Created by Razvan on 31/03/2015.
//  Copyright (c) 2015 Razvan. All rights reserved.
//

import UIKit

class PlayerBehavior: UIDynamicBehavior {
    
    
    var collisionDelagate: UICollisionBehaviorDelegate? {
        didSet {
            collisionBords.collisionDelegate = self.collisionDelagate
        }
    }
    lazy var collisionBords:UICollisionBehavior = {
        let lazyCollider = UICollisionBehavior()
        lazyCollider.translatesReferenceBoundsIntoBoundary = false
        lazyCollider.collisionMode = UICollisionBehaviorMode.Boundaries
        let bounds = UIScreen.mainScreen().bounds
        //println("Bounds: \(bounds)")
        /**/
        var path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 1, height: bounds.height))
        lazyCollider.addBoundaryWithIdentifier("bordGauche", forPath: path)
        
        path = UIBezierPath(rect: CGRect(x: bounds.width-1, y: 0, width: bounds.width-1, height: bounds.height))
        lazyCollider.addBoundaryWithIdentifier("bordDroit", forPath: path)
        
        let playerSize = bounds.height - 40 - 2
        path = UIBezierPath(rect: CGRect(x: 0, y: playerSize, width: bounds.width, height: 1))
        lazyCollider.addBoundaryWithIdentifier("limiteHaute", forPath: path)
        
        /*
        lazyCollider.addBoundaryWithIdentifier("bordGauche", fromPoint: CGPointZero, toPoint: CGPoint(x:0, y: bounds.height))
        lazyCollider.addBoundaryWithIdentifier("bordDroit", fromPoint: CGPoint(x: bounds.width, y: 0), toPoint: CGPoint(x:bounds.width, y: bounds.height))
        */
        return lazyCollider
        }()
    lazy var dynamic: UIDynamicItemBehavior = {
        let lazyDynamic = UIDynamicItemBehavior()
        lazyDynamic.elasticity = 0.0
        lazyDynamic.friction = 1
        //lazyDynamic.resistance = 1
        lazyDynamic.allowsRotation = false
        return lazyDynamic

        }()
    
    var velocity: CGFloat = {
        var valeur = 200
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            valeur += 100
        }
        
        return CGFloat(valeur)
    }();
    
    override init() {
        super.init()

        addChildBehavior(collisionBords)
        addChildBehavior(dynamic)
    }
    
    private var _player: UIView?
    
    func addPlayer(player: UIView) {
        if _player != nil {
            removePlayer()
        }
        _player = player
        collisionBords.addItem(player)
        dynamic.addItem(player)
    }
    
    func removePlayer() {
        if _player != nil {
            collisionBords.removeItem(_player!)
            dynamic.removeItem(_player!)
        }
    }
    
    func moveLeft() {
        if _player != nil && !isFin {
            dynamic.resistance = 0
            dynamic.angularResistance = 0
            let leftVelocity = -self.velocity
            let linearVelocity = dynamic.linearVelocityForItem(_player!)
            let newVelocity = leftVelocity - linearVelocity.x
            dynamic.addLinearVelocity(CGPoint(x: newVelocity, y:0), forItem: _player!)
            //println("left lv: \(dynamic.linearVelocityForItem(_player!)) - vel: \(newVelocity)")
        }
        
    }
    
    func moveRight() {
        if _player != nil && !isFin {
            dynamic.resistance = 0
            dynamic.angularResistance = 0
            let rightVelocity = self.velocity
            let linearVelocity = dynamic.linearVelocityForItem(_player!)
            let newVelocity = rightVelocity - linearVelocity.x
            dynamic.addLinearVelocity(CGPoint(x: newVelocity, y:0), forItem: _player!)
            //println("right lv: \(dynamic.linearVelocityForItem(_player!)) - vel: \(newVelocity)")
        }
        
    }
    
    func moveStop() {
        //println("Move stop")
        if _player != nil && !isFin {
            //dynamic.addLinearVelocity(CGPoint(x: 0, y:0), forItem: _player!)
            dynamic.resistance = 100
            dynamic.angularResistance = 100
            //dynamic.removeItem(_player!)
        }
    }
    
    private var isFin = false
    func end() {
        isFin = true
        dynamic.allowsRotation = true
        dynamic.resistance = 0
        dynamic.angularResistance = 0
        collisionBords.removeBoundaryWithIdentifier("limiteHaute")
        //collisionBords.translatesReferenceBoundsIntoBoundary = true
        dynamic.addLinearVelocity(CGPoint(x: CGFloat(random() % 100), y:-CGFloat(random() % 100  + 50)), forItem: _player!)
        dynamic.addAngularVelocity(CGFloat(random() % 5 - 2), forItem: _player!)
    }
    
}
