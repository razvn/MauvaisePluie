//
//  HighScore.swift
//  MauvaisePluie
//
//  Created by Razvan on 30/03/2015.
//  Copyright (c) 2015 Razvan. All rights reserved.
//

import Foundation

class HighScore: NSObject, NSCoding {
    let nom: String;
    let score: Int;
    
    
    init(nom: String, score: Int) {
        self.nom = nom
        self.score =  score
    }
    
    required init(coder aDecoder: NSCoder) {
        self.nom = aDecoder.decodeObjectForKey("nom")! as! String
        self.score = aDecoder.decodeObjectForKey("score")! as! Int
        super.init()
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.nom, forKey: "nom")
        aCoder.encodeObject(self.score, forKey: "score")
    }
    
}