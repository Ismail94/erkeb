//
//  CenterVCDelegate.swift
//  erkeb
//
//  Created by Ismail on 27/04/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit

protocol CenterVCDelegate {
    func toggleMenuLeftPanel()
    func addMenuLeftPanelViewController()
    func animateMenuLeftPanel(shouldExpand: Bool)
}
