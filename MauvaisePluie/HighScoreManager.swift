//
//  HighScoreManager.swift
//  MauvaisePluie
//
//  Created by Razvan on 30/03/2015.
//  Copyright (c) 2015 Razvan. All rights reserved.
//

import Foundation

class HighScoreManager {
    var scores: Array<HighScore> = []
    
    init() {
        //charge existing files or init an empty array
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0] as! String
        let path = documentsDirectory.stringByAppendingPathComponent("HighScore")
        let fileManager = NSFileManager.defaultManager()
        
        //does the file exists?
        if !fileManager.fileExistsAtPath(path) {
            //if not create an empty one
            if let bundle = NSBundle.mainBundle().pathForResource("DefaultFile", ofType: "plist") {
                fileManager.copyItemAtPath(bundle, toPath: path, error:nil)
            }
        }
        
         //if data then make them to array
        if let rawData = NSData(contentsOfFile: path) {
            var scoreArray: AnyObject? = NSKeyedUnarchiver.unarchiveObjectWithData(rawData)
            self.scores = scoreArray as? [HighScore] ?? []
        }
    }
    
    func save() {
        //find app save directory and save the array
        let saveData = NSKeyedArchiver.archivedDataWithRootObject(self.scores);
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray;
        let documentsDirectory = paths.objectAtIndex(0) as! NSString;
        let path = documentsDirectory.stringByAppendingPathComponent("HighScores.plist");
        
        saveData.writeToFile(path, atomically: true);
    }
    
    
    //add a new score
    func addNewScore(nom: String, newScore:Int) {
        let newHighScore = HighScore(nom: nom, score: newScore);
        self.scores.append(newHighScore);
        self.save();
    }
    
    //save the hole score list
    func addScores(scoresTuples: [(nom: String, score: Int)]) {
        scores.removeAll(keepCapacity: false)
        for score in scoresTuples {
            self.scores.append(HighScore(nom: score.nom, score: score.score))
        }
        self.save()
    }
    
    func getScores() -> [(nom: String, score: Int)] {
        var scoresTuple:[(nom: String, score: Int)] = []
        for score in scores {
            let sTuple = (nom: score.nom, score: score.score)
            scoresTuple.append(sTuple)
        }
        
        return scoresTuple
    }
}