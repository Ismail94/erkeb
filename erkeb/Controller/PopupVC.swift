//
//  PopupVC.swift
//  erkeb
//
//  Created by Ismail on 27/05/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit
import Cosmos
import TinyConstraints


class PopupVC: UIViewController {

    @IBOutlet weak var popupView: UIView!
    
    lazy var cosmosView: CosmosView = {
        var view = CosmosView()
        view.settings.filledColor = UIColor(red: 0.47, green: 0.40, blue: 1.00, alpha: 1.0)
        view.settings.filledBorderColor = UIColor(red: 0.47, green: 0.40, blue: 1.00, alpha: 1.0)
        view.settings.emptyBorderColor = UIColor(red: 0.95, green: 0.93, blue: 0.99, alpha: 1.0)
        view.settings.emptyColor = UIColor(red: 0.95, green: 0.93, blue: 0.99, alpha: 1.0)
        
        view.settings.starSize = 45
        view.settings.starMargin = 10
        view.settings.fillMode = .half
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popupView.layer.cornerRadius = 10
        popupView.layer.masksToBounds = true
        
        self.view.addSubview(self.cosmosView)
        self.cosmosView.centerInSuperview()
        
        cosmosView.didTouchCosmos = { rating in
            print("Beoordeling is \(rating)")
        }
    }
    
    @IBAction func popupBtnWasPressed(_ sender: Any) {
         dismiss(animated: true, completion: nil)
    }
    
}
