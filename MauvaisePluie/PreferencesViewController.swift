//
//  PreferencesViewController.swift
//  MauvaisePluie
//
//  Created by Razvan on 25/03/2015.
//  Copyright (c) 2015 Razvan. All rights reserved.
//

import UIKit

class PreferencesViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var imageFond: UIImageView!
    @IBOutlet weak var niveauPicker: UIPickerView!
    @IBOutlet weak var labelVersion: UILabel!
    @IBOutlet weak var versionSegment: UISegmentedControl!
    
    var dataSource : MauvaisePluieDataSource!
    var blurView: UIVisualEffectView?
    
    
    //MARK: - UI
    func addParallaxToView(view: UIView) {
        //Vertical Effect
        let verticalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y",
            type: .TiltAlongVerticalAxis)
        verticalMotionEffect.minimumRelativeValue = -20
        verticalMotionEffect.maximumRelativeValue = 20
        
        //Horizontal Effect
        let horizontalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x",
            type: .TiltAlongHorizontalAxis)
        horizontalMotionEffect.minimumRelativeValue = -20
        horizontalMotionEffect.maximumRelativeValue = 20
        
        //Group
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontalMotionEffect, verticalMotionEffect]
        
        //Add to view
        view.addMotionEffect(group)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //addParallaxToView(view)
        
        niveauPicker.delegate = self
        niveauPicker.dataSource = self
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.ExtraLight)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView!.frame = UIScreen.mainScreen().bounds
        imageFond.addSubview(blurView!)
        
        versionSegment.selectedSegmentIndex = dataSource.getVersionIndex()
        var attr = NSDictionary(object: UIFont(name: "Chalkduster", size: 20.0)!, forKey: NSFontAttributeName)
        versionSegment.setTitleTextAttributes(attr as [NSObject : AnyObject], forState: UIControlState.Normal)
        
        niveauPicker.selectRow(dataSource.getNiveauEncours().valeur-1, inComponent: 0, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func versionChanged() {
        dataSource.setVersion(versionSegment.selectedSegmentIndex)
    }
    
    @IBAction func backToRootView(sender: AnyObject) {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func dessineRect(size: CGSize) {
        blurView!.frame = CGRectMake(0, 0, size.width, size.height)
    }
    
    //MARK: - Data Sources
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return dataSource.getListeNiveaux().count
        
    }
    
    //MARK: - Delegates
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        
        return dataSource.getListeNiveaux()[row]
        
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        dataSource.setNiveau(dataSource.getListeNiveaux()[row])
        
    }
    
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView!) -> UIView {
        var pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.blackColor()
        pickerLabel.text = dataSource.getListeNiveaux()[row]
        pickerLabel.font = UIFont(name: "Chalkduster", size: 20) // In this use your custom font
        pickerLabel.textAlignment = NSTextAlignment.Center
        return pickerLabel
        
    }
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        dessineRect(size)
    }
}
