//
//  Model.swift
//  MauvaisePluie
//  Game model (global model for all the app)
//  Created by Razvan on 25/03/2015.
//  Copyright (c) 2015 Razvan. All rights reserved.
//

import Foundation

protocol MauvaisePluieDataSource {
    func isBestScore(score: Int) -> Bool
    func addScore(score: Int, nom: String)
    func setNiveau(niveau: String)
    func getListeNiveaux() -> [String]
    func getListeScores() -> [(nom: String, score: Int)]
    func getNiveauEncours() -> (nom:String, valeur: Int)
    func getScore() -> Int
    func updateScore(score: Int)
    func getActiverAppui() -> Bool
    func setActiverAppui(activer: Bool)
    func getActiverDynamic() -> Bool
    func setActiverDynamic(activer: Bool)
    func getUnAsteroide() -> String?
}

class MauvaisePluieModel: MauvaisePluieDataSource {
    
    private struct Constantes {
        static let nbAsteroidsNiveau1 = 1
        static let nbAsteroidsNiveau2 = 2
        static let nbAsteroidsNiveau3 = 3
        static let nbAsteroidsNiveau4 = 4
        static let nbAsteroidsNiveau5 = 5
    }
    
    private let _niveaux = ["Niveau 1": Constantes.nbAsteroidsNiveau1, "Niveau 2": Constantes.nbAsteroidsNiveau2, "Niveau 3": Constantes.nbAsteroidsNiveau3, "Niveau 4": Constantes.nbAsteroidsNiveau4, "Niveau 5": Constantes.nbAsteroidsNiveau5]
    
    private let _asteroids = ["asteroide-100-01","asteroide-100-02","asteroide-100-03", "asteroide-100-04", "asteroide-120-01", "asteroide-120-02", "asteroide-120-03", "asteroide-120-04"]
    
    private var _niveauChoisi: (nom:String, valeur: Int) = ("Niveau 1", Constantes.nbAsteroidsNiveau1)
    
    private var _scores:[(nom: String, score: Int)] = [("???",0),("???",0),("???",0),("???",0),("???",0)]
    
    private let _defaultScores:[(nom: String, score: Int)] = [("???",0),("???",0),("???",0),("???",0),("???",0)]

    
    private var _score = 0
    
    private var _appui = true
    
    private var _dynamic = true
    
    private var listeOrdonneeNiveaux:[String]? = nil
    
    private var highScoresManager: HighScoreManager
    
    func getScore() -> Int {
        return _score
    }
    
    func updateScore(score: Int) {
        _score = score
    }
    
    func getUnAsteroide() -> String? {
        
        if _asteroids.count > 0 {
            return _asteroids[random() % _asteroids.count]
        }
        return nil
    }
    
    func getListeNiveaux() -> [String] {
        if listeOrdonneeNiveaux != nil {
            //println("liste déjà construite")
            return listeOrdonneeNiveaux!
        } else {
            //println("liste pas encore construite")
            listeOrdonneeNiveaux = Array(_niveaux.keys).sorted{$0 < $1}
            return listeOrdonneeNiveaux!
        }
    }
    
    func getActiverAppui() -> Bool {
        return _appui
    }
    
    func setActiverAppui(activer: Bool) {
        _appui = activer
    }
    
    func getActiverDynamic() -> Bool {
        return _dynamic
    }
    
    func setActiverDynamic(activer: Bool) {
        _dynamic = activer
    }
    
    func getNiveauEncours() ->(nom:String, valeur: Int) {
        return _niveauChoisi
    }
    
    func getListeScores() -> [(nom: String, score: Int)] {
        return _scores
    }
    
    func addScore(score: Int, nom: String) {
        var ajoute = false
        
        for idx in 0..<_scores.count {
            var res = _scores[idx]
            if score  > res.score {
                _scores.insert((nom:nom, score:score), atIndex: idx)
                ajoute = true
                break
            }
        }
        
        if ajoute {
            _scores.removeLast()
        }
        
        //on sauvegarde les scores
        highScoresManager.addScores(_scores)
    }
    
    func isBestScore(score: Int)-> Bool {
        for res in _scores {
            if score > res.score {
                //println("Nouveau score: \(score), score plus petit: \(res.score), tableau scores: \(_scores)")
                return true
            }
        }
        return false;
    }
    
    func setNiveau(niveau: String) {
        if let niv = _niveaux[niveau] {
            _niveauChoisi = (nom: niveau, valeur: niv)
        } else {
            _niveauChoisi = (nom: "Niveau 1", valeur: Constantes.nbAsteroidsNiveau1)
        }
    }
    
    init() {
        highScoresManager = HighScoreManager()
        
        if  highScoresManager.scores.count > 0 {
            _scores = highScoresManager.getScores()
        } else {
            _scores = _defaultScores
        }
    }
    
}