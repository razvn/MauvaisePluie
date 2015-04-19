//
//  JeuUIDyViewController.swift
//  MauvaisePluie
//  View used for game when UIDynamic mode is choosen
//  Created by Razvan on 30/03/2015.
//  Copyright (c) 2015 Razvan. All rights reserved.
//

import UIKit
import AVFoundation

class JeuUIDyViewController: UIViewController, UICollisionBehaviorDelegate {
    
    var dataSource : MauvaisePluieDataSource!
    
    @IBOutlet weak var labelNiveau: UILabel!
    
    @IBOutlet weak var labelScore: UILabel!
    
    @IBOutlet weak var labelFin: UILabel!
    
    @IBOutlet weak var butFin: UIButton!
    
    @IBOutlet weak var butDroite: UIButton!
    
    @IBOutlet weak var butGauche: UIButton!
    
    var imageFond: UIImageView!
    
    var textViewDebug: UITextView?
    var boutonPauseDebug: UIButton?
    
    var player: UIImageView!
    
    var audioPlayer: AVAudioPlayer?
    
    
    //TODO later use a asteroid available pool - not urgent doesn't seem to use too much memory
    //private var poolAsteroidesDispo = []
    
    //MARK: - parametres/init
    private struct Constantes {
        static let Debug = false
        static let TaillePas:CGFloat = 10
        static let IndexSubiewPlayer = 1
        static let FrequenceRafraichissementVal = 20
        static let FrequenceRafraichissementFactor = 4
        static let LimiteRandomApparation = 7  //Limite de la probabilité d'apparition
        static let FrequenceTimerDebut = 1.0 //1s
        static let LongeurAsteroide = 40
        static let LargeurAsteroide = 40
        static let TailleJoueur = 40
        static let ParamMaxAsteroides = 10
        static let ParamMaxIphone = 20
        static let ParamMaxIpad = 40
        static let TempsMsgFin = 3.0 //en secondes
        static let ParamMargeIntColision:CGFloat = 7 //marge de detection de colision
        static let CountdonwFrom = 3
        static let ButtonDefaultBackground = UIColor(white: 0.7, alpha: 0.1)
        static let ButtonPressedBackground = UIColor(white: 0.7, alpha: 0.2)
        
    }
    
    private var timerJeu: NSTimer?
    private var timerDebutFin: NSTimer?
    
    private var countDown = 3
    
    private var tableauAsteroidsAffiches: [(image: UIImageView, vitesse: Int, rotation: Double, deplacement: Double, angle: Double)] = []
    
    private var isPhone = true

    private var maxScreenWidth: CGFloat = 0
    private var maxScreenHeight: CGFloat = 0
    
    private var frequenceTimerJeu: Double = 1 / 24
    
    private var niveauJeu = 1
    
    private var compteurCreationAsteroides = 0
    
    private var nombreAsteroidesAffiches = 0
    
    private var maxAsteroides = 20
    
    private var score: Int {
        didSet {
            labelScore.text = "Score: \(score)"
        }
    }
    
    private var isPartieFinie = false
    
    //asteroid behaviour
    lazy var dynamic: UIDynamicItemBehavior = {
        let lazyDynamic = UIDynamicItemBehavior()
        lazyDynamic.allowsRotation = true
        return lazyDynamic
        }()
    //collision behaviour between asteroids & player
    lazy var collision: UICollisionBehavior = {
        let lazyCollider = UICollisionBehavior()
        lazyCollider.collisionMode = UICollisionBehaviorMode.Items
        lazyCollider.collisionDelegate = self
        return lazyCollider
        }()
    //animator
    lazy var animator: UIDynamicAnimator = {
        let lazyAnimator = UIDynamicAnimator(referenceView: self.view)
        
        return lazyAnimator
        }()
    
    //player behaviour
    var playerBehavior = PlayerBehavior()
    
    private var debugAngle:Int = 0
    private var debugX:Int = 0
    private var debugY:Int = 0
    
    
    //MARK: - Timers
    //Activate main game timer
    private func startGameTimer() {
        timerJeu?.invalidate()
        timerJeu = NSTimer.scheduledTimerWithTimeInterval(frequenceTimerJeu, target: self, selector: "timerJeuTimeout", userInfo: nil, repeats: true)
    }
    //Desactivate main game timer
    private func stopGameTimer() {
        timerJeu?.invalidate()
        timerJeu = nil
    }
    
    func stopDebutimer() {
        timerDebutFin?.invalidate();
        timerDebutFin = nil
    }
    
    //MARK: - Game methods
    //Called by timer on the beging of the game
    ///Update countdown before starting the hame and when done starts the game
    func debutCountdown() {
        countDown--
        if countDown > 0 {
            labelFin.text = "\(countDown)"
        } else {
            
            //Arret du timer
            stopDebutimer()
            
            //debutPartie
            labelFin.text = "GO"
            //disparition du message go
            UIView.animateWithDuration(1.0, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                self.labelFin.alpha = 0.0
                }, completion: {finished in
                    self.labelFin.hidden = true
                    self.labelFin.alpha = 1.0
            })
            
            countDown = Constantes.CountdonwFrom
            debutPartie()
        }
    }
    
    ///End game - show message and end game animation
    func finDuJeu() {
        //arreter le timer
        stopGameTimer()
        
        //afficher le message
        labelFin.text = "ARGHHHHHHHH !!!"
        labelFin.textColor = UIColor.redColor()
        labelFin.hidden = false
        
        //desactiver les boutons
        bloquerActions()
        
        //remettre la vue au centre
        if isPhone {
            
            //play the sw music
            if let sound = audioPlayer {
                //stop the music if it's playing
                if sound.playing {
                    sound.stop()
                    sound.currentTime = 0
                }
                sound.play()
            }
            
            UIView.animateWithDuration(Double(Constantes.TempsMsgFin), animations: {
                self.imageFond.center.y = self.view.center.y
                }, completion: {finished in
                    self.allerAuxScores()
            })
        } else {
            //pour iPad y a pas d'animation de décalage
            NSTimer.scheduledTimerWithTimeInterval(Constantes.TempsMsgFin, target: self, selector: "allerAuxScores", userInfo: nil, repeats: false)
        }
    }
    
    ///Main game timer method
    func timerJeuTimeout() {
        
        //faut-il ajouter un nouvel asteroide
        if nouvelAsteroideAFaire() {
            //creer nouvel asteroide
            ajouterNouvelAsteroide()
        }
        
        //gerer les asteroides à l'écran
        //      supprime ceux sortis de l'affichage et incremente le score
        gererAsteroides()
    }
    
    ///Returns if an asteroid must be created or not
    private func nouvelAsteroideAFaire() -> Bool {
        if (nombreAsteroidesAffiches < maxAsteroides) {
            let p = random() % 101 //+ compteurCreationAsteroides
            //println("nombreAsteroidesAffiches: \(nombreAsteroidesAffiches) / maxAsteroides: \(maxAsteroides) / compteurCreationAsteroides: \(compteurCreationAsteroides)/ p: \(p)")
            return p < Constantes.LimiteRandomApparation
        }
        return false
    }
    
    ///Add a new asteroid
    private func ajouterNouvelAsteroide() {
        //choose a rendom name
        if let nomImage = dataSource.getUnAsteroide() {
            //TODO: verify if it's not available in the outofscreen asteroids pool
            //          if available, take it and remove it from the pool
            
            //Make a new image
            if let img = UIImage(named: nomImage) {
                //create the image view
                let imageView = UIImageView(image: img)
                
                //get a randomX to make the asteroid apear
                imageView.frame = CGRect(x: randomX, y: 0, width: Constantes.LargeurAsteroide, height: Constantes.LargeurAsteroide)
                
                if Constantes.Debug {
                    imageView.layer.borderColor = UIColor.blueColor().CGColor
                    imageView.layer.borderWidth = 1
                }
                //add the asteroid in the view above the player
                self.view.insertSubview(imageView, aboveSubview: player)
                
                //add the asteroid to the array of on screen asteroids
                tableauAsteroidsAffiches += [(image:imageView, vitesse: 0, rotation: 0, deplacement: 0, angle: 0)]
                
                
                dynamic.addItem(imageView)
                
                //for rotation set velocity angle between -10 and 10
                var angVelocity = CGFloat(random() % 20 - 10)
                
                //x movement beween -45 and 45
                var xpoint = CGFloat(random() % 91 - 45)
                //y between 120 and 150 for level 1, 170 and 200 for level 2, 220 and 250 for level 3, 270 and 300 for level 4 and 330 and 350 for level 5
                //formule: = 100 + variationParNiveau (random()%31) + 2 * niveau + 30 * (niveau - 1)
                var tmp = 100 + random() % 31
                tmp += 2 * niveauJeu
                tmp += 30 * (niveauJeu - 1)
                var ypoint = CGFloat(tmp)
                
                if Constantes.Debug {
                    angVelocity = CGFloat(debugAngle)
                    xpoint = CGFloat(debugX)
                    ypoint = CGFloat(debugY)
                }
                
                dynamic.addAngularVelocity(angVelocity, forItem: imageView)

                dynamic.addLinearVelocity(CGPoint(x: xpoint, y: ypoint), forItem: imageView)

                collision.addItem(imageView)
            }
            
            //count the new asteroid to the onscreen asteroids
            //todo is it usefull as we could use the tableauAsteroidsAffiches.count ?
            nombreAsteroidesAffiches++
            
            //reset the counter to 0 (used to calculate the probability to make a anstoroid apear)
            compteurCreationAsteroides = 0
        }
    }
    
    
    ///Manage onscreen asteroids
    private func gererAsteroides() {
        var nouveauTableauAsteroides:[(image: UIImageView, vitesse: Int, rotation: Double, deplacement: Double, angle: Double)] = []
        for imageAffichee in tableauAsteroidsAffiches  {
            var imageView = imageAffichee.image
            var vitesse = imageAffichee.vitesse
            var rotation = imageAffichee.rotation
            var deplacement = imageAffichee.deplacement
            var angle = imageAffichee.angle
            
            //if the asteroid is out of screen (up, down ou sides)
            if imageView.frame.minY > maxScreenHeight || imageView.frame.maxX < 0 || imageView.frame.minX > maxScreenWidth || imageView.frame.maxY
             < 0 {
                
                //step down the count of onscreen asteroides
                nombreAsteroidesAffiches--
                
                //update score if the asteroid got out of sreen by the buttom
                if imageView.frame.minY > maxScreenHeight && imageView.frame.maxX > 0 && imageView.frame.minX < maxScreenWidth {
                    score++
                }
                
                //remove the item from animation
                dynamic.removeItem(imageView)
                collision.removeItem(imageView)
                
                //remove it from the view
                imageView.removeFromSuperview()
                //println("Suppression: minY: \(imageView.frame.minY), maxX: \(imageView.frame.maxX)/0, minX: \(imageView.frame.minX)/\(maxScreenWidth) - score: \(score) - Nb aster: \(nombreAsteroidesAffiches)")
                
            } else { //asteroid is still on screen
                //println("On screen: minY: \(imageView.frame.minY), maxX: \(imageView.frame.maxX)/0, minX: \(imageView.frame.minX)/\(maxScreenWidth)")
                //step up the counter for the probability of an asteroid to aprear
                compteurCreationAsteroides++
                
                //if the asteroid minY is not completely out of the screen but bassed 3/4 of the player then remove the collision form asteroid
                // in order to not get knocked by a little bit of the asteroid passing at the butttom
                if imageView.frame.minY > player.frame.midY {
                    collision.removeItem(imageView)
                    //println("remove collision form item with y: \(imageView.frame.minY)")
                }
                
                //the asteroid is added to the array of on screen items
                let nouvelleImage = (image: imageView, vitesse: vitesse, rotation: rotation, deplacement: deplacement, angle: angle)
                nouveauTableauAsteroides.append(nouvelleImage)
            }
        }
        //upsate the asteroids with only ones on screen
        tableauAsteroidsAffiches = nouveauTableauAsteroides
        //println("Nb asteroides à l'écran: \(nombreAsteroidesAffiches)")
        if Constantes.Debug {
            textViewDebug?.text = logDebug()
        }
    }
    
    ///Collision interveption
    func collisionBehavior(behavior: UICollisionBehavior, beganContactForItem item1: UIDynamicItem, withItem item2: UIDynamicItem, atPoint p: CGPoint) {
        var isPlayer = false
        //if one of itemes of the colission is the player we stop the game
        if item1 === player || item2 === player {
            isPlayer = true
        }
        
        //add a flag that the game is over to not run again the end of the game if the player hits another asteroid durint animation
        //    we could have remove the collision on the player but wanted the player floating in space animation and eventualy hitting others asteroids
        if isPlayer && !isPartieFinie {
            println("collision")
            //the end of the game is set
            isPartieFinie = true
            
            //add a behaviour to the player so it will float in space on the screen (and not going out)
            playerBehavior.end()
            
            //go to game end
            finDuJeu()
        }
    }
    
    ///If the player collide with the bords we stop it's movements
    func collisionBehavior(behavior: UICollisionBehavior, beganContactForItem item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying, atPoint p: CGPoint) {
            playerBehavior.moveStop()
    }
    
    //MARK: - Usefull Methods
    ///returns a rendom valeur for X te origin of the asteroid ton create
    private var randomX: Int {
        var max = Int(maxScreenWidth) - Constantes.LargeurAsteroide
        
        return random() % max + 1
    }
    
    ///Init params game
    private func initParamJeu() {
        
        if dataSource != nil {
            niveauJeu = dataSource.getNiveauEncours().valeur
        }
        
        frequenceTimerJeu = 1 / Double(Constantes.FrequenceRafraichissementVal + Constantes.FrequenceRafraichissementFactor * niveauJeu)
        
        var nb = 0
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            isPhone = false
            nb = Constantes.ParamMaxIpad
        } else {
            nb = Constantes.ParamMaxIphone
            isPhone = true
        }
        
        maxAsteroides = nb + Constantes.ParamMaxAsteroides * niveauJeu
        //maxAsteroides = 2
    }
    
    ///Text to show in the debug window if it's activated
    private func logDebug() -> String {
        var retour = "Freq:\(frequenceTimerJeu)\nnbAstero/Max:\(nombreAsteroidesAffiches)/\(maxAsteroides)\n"
        
        retour += "* Player: origine: \(player.frame.origin)\n" //" | w/h: \(player.frame.width)/\(player.frame.height)"
        
        retour += "\n - Angle: \(debugAngle) - X: \(debugX) - Y: \(debugY)"
        
        /*
        var i = 1
        for element in tableauAsteroidsAffiches {
        retour += "-img \(i)-v:\(element.vitesse)-r:\(element.rotation)-d:\(element.deplacement)-a:\(element.angle)\n"
        i++
        }
        */
        
        return retour
    }
    
    ///Beginning of the game we enable buttons and start the game timer
    private func debutPartie() {
        butFin.enabled = true
        butDroite.enabled = true
        butGauche.enabled = true
        startGameTimer()
    }
    
    ///Disable buttons for no interaction during start/end animations
    private func bloquerActions() {
        butFin.enabled = false
        butDroite.enabled = false
        butGauche.enabled = false
    }
    
    
    ///Show the end of the game and goes to the Scores
    func allerAuxScores() {
        labelFin.hidden = true
        animator.removeAllBehaviors()
        println("Aller aux Scores")
        if self.storyboard != nil {
            
            //mise à jour du score
            dataSource.updateScore(score)
            
            let scoreView = self.storyboard!.instantiateViewControllerWithIdentifier("scoresView") as! ScoreViewController
            scoreView.dataSource = dataSource
            self.navigationController?.pushViewController(scoreView, animated: true)
        } else {
            println("ScoreView: Storyboard est nul")
        }
    }
    
    //MARK: - UI Events
    ///Touch on End
    @IBAction func actionFin() {
        stopGameTimer()
        allerAuxScores()
    }
    
    var moveLeftStart = false
    var moveRightStart = false
    
    ///Touch down on go left
    @IBAction func moveLeftTouchDown() {
        playerBehavior.moveLeft()
        moveLeftStart = true
        butGauche.backgroundColor = Constantes.ButtonPressedBackground
        
        println("Left down")
    }
    
    @IBAction func moveLeftTouchUp() {
        //stop
        playerBehavior.moveStop()
        moveLeftStart = false
        butGauche.backgroundColor = Constantes.ButtonDefaultBackground
        
        println("Left up")
        //if right move was also pressed go right
        if moveRightStart {
            println("Right still down")
            playerBehavior.moveRight()
        }
    }
    
    ///Touch down on go right
    @IBAction func moveRightTouchDown() {
        playerBehavior.moveRight()
        butDroite.backgroundColor = Constantes.ButtonPressedBackground
        moveRightStart = true
        println("Right down")
    }
    
    ///Stop movement on removing finger from the buttons
    @IBAction func moveRightTouchUp() {
        playerBehavior.moveStop()
        moveRightStart = false
        butDroite.backgroundColor = Constantes.ButtonDefaultBackground
        println("Right up")
        //if left move was also pressed go Left
        if moveLeftStart {
            println("Left still down")
            playerBehavior.moveLeft()
        }
    }
    
    
    ///in debug mode it's possible to pause the game
    func pauseDebug() {
        if timerJeu != nil {
            stopGameTimer()
            for item in dynamic.items {
                dynamic.removeItem(item as! UIView)
            }
        } else {
            startGameTimer()
            for item in tableauAsteroidsAffiches {
                dynamic.addItem(item.image)
            }
        }
    }
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        score = dataSource.getScore()
        labelNiveau.text = dataSource.getNiveauEncours().nom
        
        playerBehavior.collisionDelagate = self
        
        animator.addBehavior(collision)
        animator.addBehavior(dynamic)
        animator.addBehavior(playerBehavior)
        
        if let path = NSBundle.mainBundle().pathForResource("sw", ofType: "m4a") {
            audioPlayer = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: path), error: nil)
            
            if let sound = audioPlayer {
                sound.prepareToPlay()
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        initParamJeu()
        initUI()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        //animator.removeAllBehaviors()
    }
    
    ///Add of paralax effect
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
        
        // Group
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontalMotionEffect, verticalMotionEffect]
        
        // Add to the view
        view.addMotionEffect(group)
    }
    
    ///UI Init
    func initUI() {
        maxScreenHeight = UIScreen.mainScreen().bounds.height
        maxScreenWidth = UIScreen.mainScreen().bounds.width
        
        //disable buttons
        bloquerActions()
        
        //Add background image
        if let tmpImg = UIImage(named: "fond-mauvaise-pluie") {
            imageFond = UIImageView(image: tmpImg)
            imageFond.frame = CGRect(x: 0, y: 0, width: tmpImg.size.width, height: tmpImg.size.height)
            imageFond.center = self.view.center
            //on iPhone on change buttons colors and move a bit the background image
            if isPhone {
                butDroite.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                butDroite.backgroundColor = Constantes.ButtonDefaultBackground
                butGauche.backgroundColor = Constantes.ButtonDefaultBackground
                butGauche.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                butDroite.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Disabled)
                butGauche.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Disabled)
                
                //play the sw music
                if let sound = audioPlayer {
                    //stop the music if it's playing
                    if sound.playing {
                        sound.stop()
                        sound.currentTime = 0
                    }
                    sound.play()
                }
                
                //change the image location
                UIView.animateWithDuration(Double(Constantes.CountdonwFrom), animations: {
                    self.imageFond.center.y = self.view.center.y + self.maxScreenHeight / 2
                })
            } else {
                //on iPad just change buttons colors
                butDroite.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
                butGauche.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
            }
            
            self.view.insertSubview(imageFond, atIndex: 0)
            addParallaxToView(imageFond)
        }
        
        labelNiveau.textColor = UIColor.whiteColor()
        labelScore.textColor = UIColor.whiteColor()
        
        //create the player
        if let img = UIImage(named: "player") {
            player = UIImageView(image: img)
            
            //position it in the middle
            //todo: make it off screen and make it go to the middle during animation
            let xpos = maxScreenWidth / 2 - CGFloat(Constantes.TailleJoueur) / 2
            let ypos = maxScreenHeight - CGFloat(Constantes.TailleJoueur)
            
            player.frame = CGRect(x: xpos,
                y: ypos,
                width: CGFloat(Constantes.TailleJoueur),
                height: CGFloat(Constantes.TailleJoueur))
            
            //add the player above de background
            self.view.insertSubview(player, aboveSubview: imageFond)
            //add behavior to the player
            playerBehavior.addPlayer(player)
            //collisionBords.addItem(player)
            //add colision
            collision.addItem(player)
            
            //println("player.frame: \(player.frame.origin) / screenHeight: \(maxScreenHeight) / screenWidth: \(maxScreenWidth)")
        }
        
        //if debug is on add these itemes
        if Constantes.Debug {
            //frame around the player
            player.layer.borderColor = UIColor.greenColor().CGColor
            player.layer.borderWidth = 1
            
            //add a window for showing debug infos
            textViewDebug = UITextView(frame: CGRect(x: 0, y: labelScore.frame.maxY + 10, width: maxScreenWidth / 2, height: maxScreenHeight / 2))
            textViewDebug?.textColor = UIColor.greenColor()
            textViewDebug?.textAlignment = NSTextAlignment.Left
            textViewDebug?.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.2)
            textViewDebug?.editable = false
            textViewDebug?.selectable = false
            
            //add the pause button
            let pauseX = (labelNiveau.frame.midX - butFin.frame.maxX) / 2 - 30
            let pauseY = labelNiveau.frame.midX - 20
            boutonPauseDebug = UIButton(frame: CGRect(x: pauseX, y: pauseY, width: 60, height: 40))
            boutonPauseDebug?.setTitle("Pause", forState: UIControlState.Normal)
            boutonPauseDebug?.addTarget(self, action: "pauseDebug", forControlEvents: UIControlEvents.TouchUpInside)
            
            //Add sliders for testing different valeurs
            let w = 150
            let h = 40
            var x = maxScreenWidth - 160
            var y = maxScreenHeight / 2 - 20 - 40 - 10
            //angle slider
            var slider = UISlider(frame: CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(w), height: CGFloat(h)))
            slider.tintColor = UIColor.redColor()
            slider.minimumValue = -50
            slider.maximumValue = 50
            slider.addTarget(self, action: "sliderAngleChanged:", forControlEvents: UIControlEvents.ValueChanged)
            self.view.addSubview(slider)
            
            //x slider
            y = maxScreenHeight / 2 - 20
            slider = UISlider(frame: CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(w), height: CGFloat(h)))
            slider.minimumValue = -100
            slider.maximumValue = 100
            
            slider.tintColor = UIColor.greenColor()
            slider.addTarget(self, action: "sliderXChanged:", forControlEvents: UIControlEvents.ValueChanged)
            self.view.addSubview(slider)
            
            //Y slider
            y = maxScreenHeight / 2 + 20 + 10
            slider = UISlider(frame: CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(w), height: CGFloat(h)))
            slider.minimumValue = 0
            slider.maximumValue = 500
            slider.value = slider.maximumValue / 2
            
            slider.tintColor = UIColor.blueColor()
            slider.addTarget(self, action: "sliderYChanged:", forControlEvents: UIControlEvents.ValueChanged)
            self.view.addSubview(slider)
            
            
            self.view.insertSubview(textViewDebug!, aboveSubview: player)
            self.view.addSubview(boutonPauseDebug!)
            self.view.addSubview(slider)
        }
        
        //Show the countdown before begin
        labelFin.hidden = false
        labelFin.text = "\(countDown)"
        timerDebutFin = NSTimer.scheduledTimerWithTimeInterval(Constantes.FrequenceTimerDebut, target: self, selector: "debutCountdown", userInfo: nil, repeats: true)
    }
    
    
    func sliderAngleChanged(sender: UISlider) {
        var currentValue = Int(sender.value)
        debugAngle = currentValue
        println("Slider Angle: \(currentValue)")
    }
    
    func sliderXChanged(sender: UISlider) {
        var currentValue = Int(sender.value)
        debugX = currentValue
        println("Slider X: \(currentValue)")
    }
    
    func sliderYChanged(sender: UISlider) {
        var currentValue = Int(sender.value)
        debugY = currentValue
        println("Slider Y: \(currentValue)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //hide the status bar in this vue
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.score = 0
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    

    
    required init(coder aDecoder: NSCoder) {
        self.score = 0
        super.init(coder: aDecoder)
    }
}
