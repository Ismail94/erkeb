//
//  AccountTypeRounded.swift
//  erkeb
//
//  Created by Ismail on 04/05/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit

class AccountTypeRounded: UIView {

    override func awakeFromNib() {
        setupView()
    }
    
    func setupView(){
        self.layer.cornerRadius = self.frame.height / 2
    }

}
