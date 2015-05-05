//
//  JeuSKViewController.swift
//  MauvaisePluie
//
//  Created by Razvan on 22/04/2015.
//  Copyright (c) 2015 Razvan.net. All rights reserved.
//

import UIKit
import SpriteKit

class JeuSKViewController: UIViewController, JeuSceneProtocole {

    var dataSource : MauvaisePluieDataSource!
    
    var buttonRight: UIButton!
    
    var buttonLeft: UIButton!
    
    var scene: JeuScene!
    
    @IBOutlet weak var buttonEnd: UIButton!
    
    private var score = 0

    
    private struct Constants {
        static let ButtonWidth:CGFloat = 60.0
        static let ButtonWidthIpad:CGFloat = 90.0
        static let ButtonBackgroundNormal = UIColor(white: 0.7, alpha: 0.1)
        static let ButtonBackgroundHighlight = UIColor(white: 0.7, alpha: 0.2)

    }
    
    var buttonWidth: CGFloat {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Constants.ButtonWidth
        } else {
            return Constants.ButtonWidthIpad
        }
    }
    @IBAction func finJeu() {
        if self.storyboard != nil {
            
            //tell the scene to stop
            scene.stopAll()
            
            //scores update
            dataSource.updateScore(score)
            
            let scoreView = self.storyboard!.instantiateViewControllerWithIdentifier("scoresView") as! ScoreViewController
            scoreView.dataSource = dataSource
            self.navigationController?.pushViewController(scoreView, animated: true)
        } else {
            println("ScoreView: Storyboard est nul")
        }

    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scene = JeuScene(size: view.bounds.size)
        
        scene.dataSource  = self.dataSource
        scene.delegateViewController = self
        
        let skView = view as! SKView
        
        buttonRight = UIButton(frame: CGRect(x: view.frame.width - buttonWidth, y: 0, width: buttonWidth, height: view.frame.height))
        buttonRight.setTitle(">>>", forState: UIControlState.Normal)
        buttonRight.titleLabel?.font = UIFont(name: "Chalkduster", size: 20.0)
        buttonRight.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        buttonRight.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Disabled)
        buttonRight.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Highlighted)
        buttonRight.contentVerticalAlignment = UIControlContentVerticalAlignment.Bottom
        buttonRight.titleEdgeInsets.bottom =  10
        
        buttonRight.addTarget(self, action: "goRightDown", forControlEvents: UIControlEvents.TouchDown)
        buttonRight.addTarget(self, action: "goRightUp", forControlEvents: UIControlEvents.TouchUpInside)
        buttonRight.addTarget(self, action: "goRightUp", forControlEvents: UIControlEvents.TouchDragExit)
        
        buttonRight.backgroundColor = Constants.ButtonBackgroundNormal
        
        skView.addSubview(buttonRight)
        
        buttonLeft = UIButton(frame: CGRect(x: 0, y: 0, width: buttonWidth, height: view.frame.height))
        buttonLeft.setTitle("<<<", forState: UIControlState.Normal)
        buttonLeft.titleLabel?.font = UIFont(name: "Chalkduster", size: 20.0)
        buttonLeft.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        buttonLeft.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Disabled)
        buttonLeft.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Highlighted)
        buttonLeft.titleEdgeInsets.bottom =  10
        
        buttonLeft.contentVerticalAlignment = UIControlContentVerticalAlignment.Bottom
        buttonLeft.addTarget(self, action: "goLeftDown", forControlEvents: UIControlEvents.TouchDown)
        buttonLeft.addTarget(self, action: "goLeftUp", forControlEvents: UIControlEvents.TouchUpInside)
        buttonLeft.addTarget(self, action: "goLeftUp", forControlEvents: UIControlEvents.TouchDragExit)
        
        buttonLeft.backgroundColor = Constants.ButtonBackgroundNormal
        
        skView.addSubview(buttonLeft)

        /*
        skView.showsDrawCount = true
        skView.showsNodeCount = true
        skView.showsFPS = true
        skView.showsPhysics = true
        */
        skView.ignoresSiblingOrder = true
        
        scene.scaleMode = .ResizeFill
        skView.presentScene(scene)
        
    }
    
    func goRightDown() {
        
        buttonRight.backgroundColor = Constants.ButtonBackgroundHighlight
        println("moving right")
        
        scene.movePlayerRight()
    }
    
    func goLeftUp() {
        buttonLeft.backgroundColor = Constants.ButtonBackgroundNormal
        goAllUp()
    }
    
    func goRightUp() {
        buttonRight.backgroundColor = Constants.ButtonBackgroundNormal
        goAllUp()
    }
    
    func goAllUp() {
        println("stop movint")
        scene.stopPlayer()
    }
    
    func goLeftDown() {
        
        buttonLeft.backgroundColor = Constants.ButtonBackgroundHighlight
        println("moving left")
        scene.movePlayerLeft()
    }

    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: -JeuSceneDelegate
    func animationStartBegin() {
        //hidde finish button
        buttonEnd.hidden = true
    }
    
    func animationStartEnd() {
        //activate finish button
        buttonEnd.hidden = false
    }
    
    func animationFinishStart() {
        buttonEnd.hidden = true
    }
    
    func animationFinishEnd() {
        //buttonEnd.hidden = true
        finJeu()
    }
    
    func getScore()->Int {
        return score
    }
    
    func incrementScore() -> Int {
        score++
        return score
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
