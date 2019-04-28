//
//  RoundedTextField.swift
//  erkeb
//
//  Created by Ismail on 28/04/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit

class RoundedTextField: UITextField {

    override func awakeFromNib() {
        setupView()
    }
    
    
    
    func setupView() {
        self.layer.cornerRadius = 1.0
        self.clipsToBounds = true
    }

}
