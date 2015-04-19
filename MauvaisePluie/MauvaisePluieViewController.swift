//
//  ViewController.swift
//  MauvaisePluie
//  Main controller of the app taht let choose which view to go to
//  Created by Razvan on 24/03/2015.
//  Copyright (c) 2015 Razvan. All rights reserved.
//

import UIKit

class MauvaisePluieViewController: UIViewController {

    @IBOutlet weak var labelNiveau: UILabel!
    @IBOutlet weak var labelVersion: UILabel!
    
    @IBOutlet weak var imageFond: UIImageView!
    
    lazy var dataSource : MauvaisePluieDataSource! = MauvaisePluieModel()
    
    func addParallaxToView(view: UIView) {
        //Vertical effect
        let verticalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y",
            type: .TiltAlongVerticalAxis)
        verticalMotionEffect.minimumRelativeValue = -20
        verticalMotionEffect.maximumRelativeValue = 20
        
        //Horizontal effect
        let horizontalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x",
            type: .TiltAlongHorizontalAxis)
        horizontalMotionEffect.minimumRelativeValue = -20
        horizontalMotionEffect.maximumRelativeValue = 20
        
        //Group
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontalMotionEffect, verticalMotionEffect]
        
        //Add to the view
        view.addMotionEffect(group)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addParallaxToView(imageFond)

    }

    override func viewWillAppear(animated: Bool) {
        labelNiveau.text = dataSource.getNiveauEncours().nom
        if (dataSource.getActiverDynamic()) {
            labelVersion.text = "(version UIDynamics)"
        } else {
            labelVersion.text = "(version NSTimer)"
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func showScoreView() {
        if self.storyboard != nil {
            let scoreView = self.storyboard!.instantiateViewControllerWithIdentifier("scoresView") as! ScoreViewController
            scoreView.dataSource = dataSource
            self.navigationController?.pushViewController(scoreView, animated: true)
        } else {
            println("Storyboard est nul")
        }
        
    }
    
    
    @IBAction func showJeuView() {
        if self.storyboard != nil {
            
            if dataSource.getActiverDynamic() {
                let jeuView = self.storyboard!.instantiateViewControllerWithIdentifier("jeuViewDyn") as! JeuUIDyViewController
                
                dataSource.updateScore(0)
                jeuView.dataSource = dataSource
                self.navigationController?.pushViewController(jeuView, animated: true)
            } else {
                let jeuView = self.storyboard!.instantiateViewControllerWithIdentifier("jeuView") as! JeuViewController
                
                dataSource.updateScore(0)
                jeuView.dataSource = dataSource
                self.navigationController?.pushViewController(jeuView, animated: true)
            }
            
        } else {
            println("JeuView: Storyboard est nul")
        }
    }
    
    @IBAction func showPreferencesView() {
        if self.storyboard != nil {
            let preferecesView = self.storyboard!.instantiateViewControllerWithIdentifier("preferecesView") as! PreferencesViewController
            preferecesView.dataSource = dataSource
            self.navigationController?.pushViewController(preferecesView, animated: true)
        } else {
            println("Storyboard est nul")
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
}

