//
//  ScoreViewController.swift
//  MauvaisePluie
//
//  Created by Razvan on 25/03/2015.
//  Copyright (c) 2015 Razvan. All rights reserved.
//

import UIKit

class ScoreViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var imageFond: UIImageView!
    @IBOutlet weak var labelNom1: UILabel!
    @IBOutlet weak var labelScore1: UILabel!
    @IBOutlet weak var labelNom2: UILabel!
    @IBOutlet weak var labelScore2: UILabel!
    @IBOutlet weak var labelNom3: UILabel!
    @IBOutlet weak var labelScore3: UILabel!
    @IBOutlet weak var labelNom4: UILabel!
    @IBOutlet weak var labelScore4: UILabel!
    @IBOutlet weak var labelNom5: UILabel!
    @IBOutlet weak var labelScore5: UILabel!
    @IBOutlet weak var tfNom: UITextField!
    @IBOutlet weak var labelVotreScore: UILabel!
    
    var dataSource : MauvaisePluieDataSource!
    var blurView: UIVisualEffectView?
    
    private func updateUI() {
        let scores = dataSource.getListeScores()
        var score = scores[0]
        labelNom1.text = score.nom
        labelScore1.text = "\(score.score)"
        score = scores[1]
        labelNom2.text = score.nom
        labelScore2.text = "\(score.score)"
        score = scores[2]
        labelNom3.text = score.nom
        labelScore3.text = "\(score.score)"
        score = scores[3]
        labelNom4.text = score.nom
        labelScore4.text = "\(score.score)"
        score = scores[4]
        labelNom5.text = score.nom
        labelScore5.text = "\(score.score)"
        
        let dernierScore = dataSource.getScore()
        labelVotreScore.text = "\(dernierScore)"
        
        tfNom.hidden = !dataSource.isBestScore(dernierScore)
        
        blurView!.frame = UIScreen.mainScreen().bounds
        //println("blurVew: \(blurView!.frame)")
        
        
    }
    
    func addParallaxToView(view: UIView) {
        //vertical deffect
        let verticalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y",
            type: .TiltAlongVerticalAxis)
        verticalMotionEffect.minimumRelativeValue = -20
        verticalMotionEffect.maximumRelativeValue = 20
        
        //horizontal effect
        let horizontalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x",
            type: .TiltAlongHorizontalAxis)
        horizontalMotionEffect.minimumRelativeValue = -20
        horizontalMotionEffect.maximumRelativeValue = 20
        
        //Group
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontalMotionEffect, verticalMotionEffect]
        
        //add to view
        view.addMotionEffect(group)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //addParallaxToView(imageFond)
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        blurView = UIVisualEffectView(effect: blurEffect)
        
        //For handling the keyboard appear that hide the input field
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        
        imageFond.addSubview(blurView!)
        tfNom.delegate = self
        
        updateUI()
    }

    func keyboardWillShow(notification: NSNotification) {
        //println("keyboard show")
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            //println("Hello iPhone")
            animateNomWithKeyboard(notification, show: true)
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        //println("keyboard hide")
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            //println("Hello iPhone")
            animateNomWithKeyboard(notification, show: false)
        }
    }
    
    func animateNomWithKeyboard(notification: NSNotification, show: Bool) {
        
        let userInfo = notification.userInfo!
        
        let keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        if show {
            self.view.frame.origin.y -= keyboardSize.height
        } else {
            self.view.frame.origin.y += keyboardSize.height
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        view.endEditing(true)
        //println("textfield: touches begun")
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        //println("textfield: return")
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        //println("textfield: edit ended")
        if !textField.text.isEmpty {
            dataSource.addScore(labelVotreScore.text!.toInt()!, nom: textField.text)
            dataSource.updateScore(0)
            textField.text = ""
        }
        updateUI()
    }
    
    func dessineRect(size: CGSize) {
        blurView!.frame = CGRectMake(0, 0, size.width, size.height)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        dessineRect(size)
    }

    @IBAction func backToRootView(sender: AnyObject) {
         self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
