//
//  JeuViewController.swift
//  MauvaisePluie
//  View for game when NSTimer mode is on‡
//  Created by Razvan on 26/03/2015.
//  Copyright (c) 2015 Razvan. All rights reserved.
//

import UIKit

class JeuViewController: UIViewController {
    
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
    
    
    //Si on a le temps on va gerer le un pool de dispo (hors de l'écran)
    // mais pas urgent car pour le moment pas de grosse conso mémoire constatée
    //private var poolAsteroidesDispo = []
    
    //MARK: - parametres/init
    private struct Constantes {
        static let Debug = false
        static let TaillePas:CGFloat = 10
        static let IndexSubiewPlayer = 1
        static let FrequenceRafraichissementVal = 20
        static let FrequenceRafraichissementFactor = 4
        static let LimiteRandomApparation = 20  //Limite de la probabilité d'apparition
        static let FrequenceTimerDebut = 1.0 //1s
        static let LongeurAsteroide = 40
        static let LargeurAsteroide = 40
        static let TailleJoueur = 40
        static let ParamMaxAsteroides = 10
        static let ParamMaxIphone = 20
        static let ParamMaxIpad = 50
        static let TempsMsgFin = 3.0 //en secondes
        static let ParamMargeIntColision:CGFloat = 7 //marge de detection de colision
        static let ParamMargeAsteoColision:CGFloat = 10 //marge de detection de colision asteroides
        static let CountdonwFrom = 3
        static let ButtonBackgroundNormal = UIColor(white: 0.7, alpha: 0.1)
        static let ButtonBackgroundHighlight = UIColor(white: 0.7, alpha: 0.2)

        
    }
    
    private var timerDeplacement: NSTimer?
    private var timerJeu: NSTimer?
    private var timerDebutFin: NSTimer?
    
    private var countDown = 3
    
    private var tableauAsteroidsAffiches: [(image: UIImageView, vitesse: Int, rotation: Double, deplacement: Double, angle: Double)] = []
    
    private var isPhone = true
    private var angleRotation:CGFloat = 0.0
    private var maxScreenWidth: CGFloat = 0
    private var maxScreenHeight: CGFloat = 0
    
    private var frequenceTimerJeu: Double = 1 / 24
    
    private var niveauJeu = 1
    
    private var compteurCreationAsteroides = 0
    
    private var nombreAsteroidesAffiches = 0
    
    private var maxAsteroides = 30
    
    private var score: Int {
        didSet {
            labelScore.text = "Score \(score)"
        }
    }
    
    private var vitesseVerticale: Int {
        return random() % (2 * niveauJeu) + 1
    }
    
    private var rotationAngle: Double {
        //Variation de -0.2 à +0.2
        return Double(random() % 5 - 2) / 10
    }
    
    private var deplacementX: Double {
        //deplacelement horizontal aléatoire de -3 à 3 pixels
        
        return Double(random() % 21 - 10) / 10
    }
    
    //MARK: - Timers
    //Activer timer pricipal du jeu
    private func startGameTimer() {
        timerJeu?.invalidate()
        timerJeu = NSTimer.scheduledTimerWithTimeInterval(frequenceTimerJeu, target: self, selector: "timerJeuTimeout", userInfo: nil, repeats: true)
    }
    //Desactiver timer pricipal du jeu
    private func stopGameTimer() {
        timerJeu?.invalidate()
        timerJeu = nil
    }
    
    //timer déplacement (pour déplacer le joueur tant que le bouton est appuié
    func startMoveTimer(left: Bool) {
        timerDeplacement?.invalidate()
        if left {
            timerDeplacement = NSTimer.scheduledTimerWithTimeInterval(frequenceTimerJeu, target: self, selector: "goLeft", userInfo: nil, repeats: true)
        } else {
            timerDeplacement = NSTimer.scheduledTimerWithTimeInterval(frequenceTimerJeu, target: self, selector: "goRight", userInfo: nil, repeats: true)
        }
    }
    
    func stopMoveTimer() {
        timerDeplacement?.invalidate();
        timerDeplacement = nil
    }
    
    func stopDebutimer() {
        timerDebutFin?.invalidate();
        timerDebutFin = nil
    }
    
    
    //MARK: - Game methods
    //Appellé par le timer de debut de partie
    //mise à jour du countdown avant début et commence la partie
    func debutCountdown() {
        countDown--
        if countDown > 0 {
            labelFin.text = "\(countDown)"
        } else {
            
            //Arret du timer
            stopDebutimer()
            
            //debutPartie
            labelFin.text = "Go"
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
    
    ///Boucle pricipale de jeu
    func timerJeuTimeout() {
        //faut-il ajouter un nouvel asteroide
        if nouvelAsteroideAFaire() {
            //creer nouvel asteroide
            ajouterNouvelAsteroide()
        }
        
        //déplacer les asteroides à l'écran
        //      supprime ceux sortis de l'affichage et incremente le score
        avancerAsteroides()
        
        //si colision aver player
        if colisionAvecJouer() {
            //arreter les timers
            desactiverTimersJeu()
            
            //afficher le message
            labelFin.text = "Arghhhhhhh!!!"
            labelFin.textColor = UIColor.redColor()
            labelFin.hidden = false
            
            //desactiver les boutons
            bloquerActions()
            
            //remettre la vue au centre
            if isPhone {
                UIView.animateWithDuration(Double(Constantes.TempsMsgFin), animations: {
                    self.imageFond.center.y = self.view.center.y
                    }, completion: {finished in
                        self.finJeuAllerScores()
                })
            } else { //pour iPad y a pas d'animation de décalage
                //aller aux scores après quelques secondes
                NSTimer.scheduledTimerWithTimeInterval(Constantes.TempsMsgFin, target: self, selector: "finJeuAllerScores", userInfo: nil, repeats: false)
            }
        }
    }
    
    ///Retourne s'il faut ou pas créer un nouvel asteroide
    private func nouvelAsteroideAFaire() -> Bool {
        if (nombreAsteroidesAffiches < maxAsteroides) {
            let p = random() % 101 //+ compteurCreationAsteroides
            //println("nombreAsteroidesAffiches: \(nombreAsteroidesAffiches) / maxAsteroides: \(maxAsteroides) / compteurCreationAsteroides: \(compteurCreationAsteroides)/ p: \(p)")
            return p < Constantes.LimiteRandomApparation
        }
        return false
    }
    
    ///Ajoute un nouvel asteroide soit en prenant du pool si présent sinon le créant
    private func ajouterNouvelAsteroide() {
        //prendre un nom d'image au hasard
        if let nomImage = dataSource.getUnAsteroide() {
            //vérifier s'il n'y pas une dispo dans le pool
            //si oui le prendre et le supprimer du pool
            
            //sinon creer un nouveau
            if let img = UIImage(named: nomImage) {
                //creer l'image view
                let imageView = UIImageView(image: img)
                //calculer un random x pour l'affichage
                
                imageView.frame = CGRect(x: randomX, y: 0, width: Constantes.LargeurAsteroide, height: Constantes.LargeurAsteroide)
                
                if Constantes.Debug {
                    imageView.layer.borderColor = UIColor.blueColor().CGColor
                    imageView.layer.borderWidth = 1
                }
                //self.view.addSubview(imageView)
                self.view.insertSubview(imageView, aboveSubview: player)
                tableauAsteroidsAffiches += [(image:imageView, vitesse: vitesseVerticale, rotation: rotationAngle, deplacement: deplacementX, angle: 0)]
            }
            
            //ajouter le nouveau au pool d'asteroides à avancer
            // pas nécessaire la mémoire n'a pas l'air d'être impactée
            
            //incremente le nombre d'asteroides à l'écran
            nombreAsteroidesAffiches++
            
            //initialiser à 0 le compteur
            compteurCreationAsteroides = 0
        }
    }
    
    ///Avance les asteroides à l'écran
    private func avancerAsteroides() {
        var nouveauTableauAsteroides:[(image: UIImageView, vitesse: Int, rotation: Double, deplacement: Double, angle: Double)] = []
        for imageAffichee in tableauAsteroidsAffiches  {
            var imageView = imageAffichee.image
            var vitesse = imageAffichee.vitesse
            var rotation = imageAffichee.rotation
            var deplacement = imageAffichee.deplacement
            var angle = imageAffichee.angle
            
            //si l'asteroide est hors de l'écran (en hauteur ou largeur
            if imageView.frame.minY > maxScreenHeight || imageView.frame.maxX < 0 || imageView.frame.minX > maxScreenWidth {
                //suppression de la vue
                imageView.removeFromSuperview()
                //println("Suppression: minY: \(imageView.frame.minY), maxX: \(imageView.frame.maxX)/0, minX: \(imageView.frame.minX)/\(maxScreenWidth)")
                
                //decrementer les asteroides à l'écran
                nombreAsteroidesAffiches--
                
                //augmenter le score que pour les asteroides sortis par le bas
                if imageView.frame.minY > maxScreenHeight && imageView.frame.maxX > 0 && imageView.frame.minX < maxScreenHeight {
                    score++
                }
                
            } else { //on déplace que si on est dans l'écran
                
                angle = angle +  frequenceTimerJeu * M_PI + rotation
                if angle > 6.28 {
                    angle = 0.0
                }
                
                imageView.center.y = imageView.center.y + CGFloat(vitesse)
                imageView.center.x = imageView.center.x + CGFloat(deplacement)
                
                
                var transform1 = CGAffineTransformMakeRotation(CGFloat(angle));
                var transform2 = CGAffineTransformMakeTranslation(imageView.center.x, imageView.center.y)
                imageView.transform = CGAffineTransformConcat(transform1, transform2)
                
                //incremente les asteroides à l'écran
                compteurCreationAsteroides++
                
                //on le garde dans le tableau
                let nouvelleImage = (image: imageView, vitesse: vitesse, rotation: rotation, deplacement: deplacement, angle: angle)
                nouveauTableauAsteroides.append(nouvelleImage)
            }
        }
        //on met à jour le tableau d'asteroides avec le nouveau en ne gardant que ceux à l'écran
        tableauAsteroidsAffiches = nouveauTableauAsteroides
        //println("Nb asteroides à l'écran: \(nombreAsteroidesAffiches)")
        if Constantes.Debug {
            textViewDebug?.text = logDebug()
        }
    }
    
    ///Teste s'il y a collision avec le joueur
    private func colisionAvecJouer()->Bool {
        for element in tableauAsteroidsAffiches {
            var astero = element.image
            //on les fait un peu plus petites à cause des coins
            let frame1 = CGRect(x: astero.frame.origin.x + Constantes.ParamMargeAsteoColision,
                y: astero.frame.origin.y + Constantes.ParamMargeAsteoColision,
                width: astero.frame.width - Constantes.ParamMargeAsteoColision * 2,
                height: astero.frame.height - Constantes.ParamMargeAsteoColision * 2)
            
            let frame2 = CGRect(x: player.frame.origin.x + Constantes.ParamMargeIntColision / 2,
                y: player.frame.origin.y,
                width: player.frame.width - Constantes.ParamMargeIntColision,
                height: player.frame.height - Constantes.ParamMargeIntColision)
            
            if (CGRectIntersectsRect(frame1, frame2)) {
                if Constantes.Debug {
                    astero.layer.borderColor = UIColor.redColor().CGColor
                    astero.layer.borderWidth = 2
                    var view1 = UIView(frame: frame1)
                    view1.backgroundColor = UIColor.redColor()
                    view1.alpha = 0.5
                    self.view.addSubview(view1)
                    
                    view1 = UIView(frame: frame2)
                    view1.backgroundColor = UIColor.greenColor()
                    view1.alpha = 0.5
                    self.view.addSubview(view1)
                }
                return true
            }
        }
        
        return false
    }
    
    //MARK: - Déplacement joueur
    ///Déplacer joueur à gauche
    func goLeft() {
        var diff = player.frame.origin.x - Constantes.TaillePas
        //println("left: origine.x: \(player.frame.origin.x)")
        
        if diff < 0 {
            diff = 0
        } else {
            diff = CGFloat(vitesseVerticale * 2) //Constantes.TaillePas
        }
        //println("left: diff: \(diff)")
        
        player.frame.offset(dx: -diff, dy: 0)
    }
    
    ///Déplacer joueur à droite
    func goRight() {
        
        var diff = player.frame.origin.x + player.frame.width + CGFloat(vitesseVerticale * 2) //Constantes.TaillePas
        //println("right: origine.x: \(player.frame.origin.x) - screen.bounds.width: \(maxScreenWidth)")
        
        if diff > maxScreenWidth {
            diff = 0
        } else {
            diff = CGFloat(vitesseVerticale * 2) //Constantes.TaillePas
        }
        //println("right: diff: \(diff)")
        
        //player.frame.offset(dx: diff, dy: 0)
        player.center = CGPoint(x: player.center.x + diff, y: player.center.y)
    }
    
    //MARK: - Methodes utiles
    ///Désactive les timers de jeu et déplacement
    private func desactiverTimersJeu() {
        stopGameTimer()
        stopMoveTimer()
    }
    
    ///retourner une valeur aléatoire de x pour l'origine de l'astertoide à créer
    private var randomX: Int {
        var max = Int(maxScreenWidth) - Constantes.LargeurAsteroide
        
        return random() % max + 1
    }
    
    ///Initialisation des paramètres la partie
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
    }
    
    ///Texte à afficher dans la fenetre de debug
    private func logDebug() -> String {
        var retour = "Freq:\(frequenceTimerJeu)\nnbAstero/Max:\(nombreAsteroidesAffiches)/\(maxAsteroides)\n"
        
        retour += "* Player: origine: \(player.frame.origin)\n" //" | w/h: \(player.frame.width)/\(player.frame.height)"
        
        var i = 1
        for element in tableauAsteroidsAffiches {
            retour += "-img \(i)-v:\(element.vitesse)-r:\(element.rotation)-d:\(element.deplacement)-a:\(element.angle)\n"
            i++
        }
        
        return retour
    }
    
    ///Active les boutons de la partie et lance le timer du jeu
    private func debutPartie() {
        butFin.enabled = true
        butDroite.enabled = true
        butGauche.enabled = true
        startGameTimer()
    }
    
    ///Desactive les boutons de la partie (pour pas y toucher pendant l'animation de début et fin)
    private func bloquerActions() {
        butFin.enabled = false
        butDroite.enabled = false
        butGauche.enabled = false
    }
    
    
    ///Marque la fin du jeu et va aux scores
    func finJeuAllerScores() {
        labelFin.hidden = true
        //println("finJeuAllerScores")
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
    ///Touche sur fin
    @IBAction func actionFin() {
        desactiverTimersJeu()
        finJeuAllerScores()
    }
    
    ///Appui pour aller à gauche
    @IBAction func moveLeftTouchDown() {
        butGauche.backgroundColor = Constantes.ButtonBackgroundHighlight
        goLeft()
        if dataSource.getActiverAppui() {
            startMoveTimer(true)
        }
    }
    
    ///Appui pour aller à droite
    @IBAction func moveRightTouchDown() {
        butDroite.backgroundColor = Constantes.ButtonBackgroundHighlight
        goRight()
        if dataSource.getActiverAppui() {
            startMoveTimer(false)
        }
    }
    
    ///Arret d'appui sur les touches de déplacement
    @IBAction func moveTouchUp(sender: UIButton) {
        if sender === butDroite {
            butDroite.backgroundColor = Constantes.ButtonBackgroundNormal
        } else if sender === butGauche {
            butGauche.backgroundColor = Constantes.ButtonBackgroundNormal
        }
        stopMoveTimer()
    }
    
    ///Arret d'appui sur les touches de déplacement
    @IBAction func moveTouchEnded(sender: UIButton) {
        if sender === butDroite {
            butDroite.backgroundColor = Constantes.ButtonBackgroundNormal
        } else if sender === butGauche {
            butGauche.backgroundColor = Constantes.ButtonBackgroundNormal
        }
        stopMoveTimer()
    }
    
    func pauseDebug() {
        if timerJeu != nil {
            stopGameTimer()
        } else {
            startGameTimer()
        }
    }
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        labelNiveau.textColor = UIColor.whiteColor()
        labelScore.textColor = UIColor.whiteColor()
        
        score = dataSource.getScore()
        labelNiveau.text = dataSource.getNiveauEncours().nom
    }
    
    override func viewWillAppear(animated: Bool) {
        initParamJeu()
        initUI()
    }
    
    func addParallaxToView(view: UIView) {
        //Effet vertical
        let verticalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y",
            type: .TiltAlongVerticalAxis)
        verticalMotionEffect.minimumRelativeValue = -10
        verticalMotionEffect.maximumRelativeValue = 10
        
        //Effet horizontal
        let horizontalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x",
            type: .TiltAlongHorizontalAxis)
        horizontalMotionEffect.minimumRelativeValue = -10
        horizontalMotionEffect.maximumRelativeValue = 10
        
        // Groupe
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontalMotionEffect, verticalMotionEffect]
        
        // ajout à la vue
        view.addMotionEffect(group)
    }
    
    ///Initialisation de l'IHM
    func initUI() {
        maxScreenHeight = UIScreen.mainScreen().bounds.height
        maxScreenWidth = UIScreen.mainScreen().bounds.width
        
        //desactiver les boutons
        bloquerActions()
        
        //Ajoute l'image de fond
        if let tmpImg = UIImage(named: "fond-mauvaise-pluie") {
            imageFond = UIImageView(image: tmpImg)
            imageFond.frame = CGRect(x: 0, y: 0, width: tmpImg.size.width, height: tmpImg.size.height)
            imageFond.center = self.view.center
            //si on est sur un Phone on descend un peu l'image
            if isPhone {
                butDroite.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                butGauche.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                butDroite.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Disabled)
                butGauche.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Disabled)
                butDroite.backgroundColor = Constantes.ButtonBackgroundNormal
                butGauche.backgroundColor = Constantes.ButtonBackgroundNormal
                
                UIView.animateWithDuration(Double(Constantes.CountdonwFrom), animations: {
                    self.imageFond.center.y = self.view.center.y + self.maxScreenHeight / 2
                })
            } else {
                //si on est sur iPad on change la couleur des boutons de déplacement
                butDroite.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
                butGauche.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
            }
            
            self.view.insertSubview(imageFond, atIndex: 0)
            
            addParallaxToView(imageFond)
        }
        
        //creation du player
        if let img = UIImage(named: "player") {
            player = UIImageView(image: img)
            
            //position en bas au milieu
            let ratio = img.size.width / img.size.height
            let playerHeight = CGFloat(Constantes.TailleJoueur)/ratio
            let xpos = maxScreenWidth / 2 - CGFloat(Constantes.TailleJoueur) / 2
            let ypos = maxScreenHeight - playerHeight
            
            
            player.frame = CGRect(x: xpos,
                y: ypos,
                width: CGFloat(Constantes.TailleJoueur),
                height: CGFloat(playerHeight))
            
            
            //ajout du joueur sur l'image du fond
            self.view.insertSubview(player, aboveSubview: imageFond)
            
            //si on active le debug
            if Constantes.Debug {
                //affichage du contour de la frame du joueur
                player.layer.borderColor = UIColor.greenColor().CGColor
                player.layer.borderWidth = 1
                
                //affiche une fenetre d'affichage d'infos
                textViewDebug = UITextView(frame: CGRect(x: 0, y: labelScore.frame.maxY + 10, width: maxScreenWidth / 2, height: maxScreenHeight / 2))
                textViewDebug?.textColor = UIColor.greenColor()
                textViewDebug?.textAlignment = NSTextAlignment.Left
                textViewDebug?.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.2)
                textViewDebug?.editable = false
                textViewDebug?.selectable = false
                
                //ajout du bouton pause
                boutonPauseDebug = UIButton(frame: CGRect(x: maxScreenWidth - 90, y: maxScreenHeight / 2 - 20, width: 80, height: 40))
                boutonPauseDebug?.setTitle("Pause", forState: UIControlState.Normal)
                boutonPauseDebug?.addTarget(self, action: "pauseDebug", forControlEvents: UIControlEvents.TouchUpInside)
                
                self.view.insertSubview(textViewDebug!, aboveSubview: player)
                self.view.addSubview(boutonPauseDebug!)
            }
            //println("player.frame: \(player.frame.origin) / screenHeight: \(maxScreenHeight) / screenWidth: \(maxScreenWidth)")
        }
        
        
        //Affiche le countdown avant début
        labelFin.hidden = false
        labelFin.text = "\(countDown)"
        timerDebutFin = NSTimer.scheduledTimerWithTimeInterval(Constantes.FrequenceTimerDebut, target: self, selector: "debutCountdown", userInfo: nil, repeats: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
