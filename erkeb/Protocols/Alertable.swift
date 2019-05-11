//
//  Alertable.swift
//  erkeb
//
//  Created by Ismail on 11/05/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit

protocol Alertable  {}

extension Alertable where Self: UIViewController {
    //Hier kan ik een alert weergeven met een custom bericht
    func showAlert(_ msg: String){
        let alertController = UIAlertController(title: "⛔️⛔️⛔️", message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }
}
