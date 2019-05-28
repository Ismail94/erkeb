//
//  ProfielVC.swift
//  erkeb
//
//  Created by Ismail on 24/05/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit
import Firebase

class ProfielVC: UIViewController {

    let currentUserId = Auth.auth().currentUser?.uid
    
    @IBOutlet weak var userMailLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if currentUserId != nil {
            userMailLbl.text = Auth.auth().currentUser?.email
        }
    }
    
    @IBAction func backBtnWasPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
