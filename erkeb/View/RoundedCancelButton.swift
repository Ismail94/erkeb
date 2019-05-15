//
//  RoundedCancelButton.swift
//  erkeb
//
//  Created by Ismail on 15/05/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit

class RoundedCancelButton: UIButton {

    //huidige button grootte
    var originalSize: CGRect?
    
    override func awakeFromNib() {
        setupView()
    }
    
    func setupView(){
        self.layer.shadowRadius = 8.0
    }

}
