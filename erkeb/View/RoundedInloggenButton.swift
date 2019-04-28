//
//  RoundedInloggenButton.swift
//  erkeb
//
//  Created by Ismail on 28/04/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit

class RoundedInloggenButton: UIButton {

    override func awakeFromNib() {
        setupView()
    }
    
    func setupView(){
        self.layer.cornerRadius = 3.0
    }
}
