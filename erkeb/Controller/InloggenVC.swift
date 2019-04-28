//
//  InloggenVC.swift
//  erkeb
//
//  Created by Ismail on 27/04/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit

class InloggenVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.bindToKeyboard()
        
        //tap somewhere on the screen to hide keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(moveKeyboardTap))
        self.view.addGestureRecognizer(tap)
    }
    
    //stop the editing mode (when you put text inside the field)
    @objc func moveKeyboardTap(sender: UITapGestureRecognizer){
        self.view.endEditing(true)
    }
    
    @IBAction func cancelBtnWasPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
       
    }
    
  

}
