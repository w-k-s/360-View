//
//  ViewController.swift
//  View360
//
//  Created by Waqqas Sheikh on 8/5/16.
//  Copyright © 2016 asfour. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var surroundView : SurroundView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func resetFirstAttitude(){
        self.surroundView.resetFirstAttitude()
    }
}

