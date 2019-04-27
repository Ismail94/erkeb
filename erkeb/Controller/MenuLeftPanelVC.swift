//
//  MenuLeftPanelVC.swift
//  erkeb
//
//  Created by Ismail on 26/04/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit

class MenuLeftPanelVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func inloggenBtnWasPressed(_ sender: Any) {
        //Access storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let inloggenVC = storyboard.instantiateViewController(withIdentifier: "InloggenVC") as? InloggenVC
        present(inloggenVC!, animated: true, completion: nil)
    }
    
}
