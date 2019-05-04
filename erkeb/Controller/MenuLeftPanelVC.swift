//
//  MenuLeftPanelVC.swift
//  erkeb
//
//  Created by Ismail on 26/04/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit
import Firebase

class MenuLeftPanelVC: UIViewController {
    
    let appDelegate = AppDelegate.getAppDelegate()
    
    let currentUserId = Auth.auth().currentUser?.uid
    
    @IBOutlet weak var userImageView: RoundedImageView!
    @IBOutlet weak var userMailLbl: UILabel!
    @IBOutlet weak var userAccountTypeLbl: UILabel!
    @IBOutlet weak var userAccountView: AccountTypeRounded!
    @IBOutlet weak var inUitloggenBtn: UIButton!
    @IBOutlet weak var switchBtn: UISwitch!
    @IBOutlet weak var pickupModeLbl: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

    }
    
    //Dankzij dit functie gaan de elementen al gestart zijn voordat ze te zien zijn
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        switchBtn.isOn = false
        switchBtn.isHidden = true
        pickupModeLbl.isHidden = true
        switchBtn.transform = CGAffineTransform(scaleX: 0.70, y: 0.70)
        
        checkPassagiersEnBestuurders()
        
        //Als je geen acount beschikt dan kan je alleen het registreer knop zien
        if Auth.auth().currentUser == nil {
            userMailLbl.text = ""
            userAccountTypeLbl.text = ""
            userAccountView.isHidden = true
            userImageView.isHidden = true
            inUitloggenBtn.setTitle("Inloggen", for: .normal)
        } else {
            userMailLbl.text = Auth.auth().currentUser?.email
            userAccountTypeLbl.text = ""
            userAccountView.isHidden = false
            userImageView.isHidden = false
            inUitloggenBtn.setTitle("Uitloggen", for: .normal)
        }
    }
    
    //check als het een passagier of een bestuurder het acount gebruikt
    func checkPassagiersEnBestuurders(){
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for snap in snapshot{
                    if snap.key == Auth.auth().currentUser?.uid{
                        self.userAccountTypeLbl.text = "Passagier"
                    }
                }
            }
        })
        
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for snap in snapshot{
                    if snap.key == Auth.auth().currentUser?.uid{
                        self.userAccountTypeLbl.text = "Bestuurder"
                        self.switchBtn.isHidden = false
                        
                        let switchStatus = snap.childSnapshot(forPath: "isPickupModeEnabled").value as! Bool
                        self.switchBtn.isOn = switchStatus
                        self.pickupModeLbl.isHidden = false
                    }
                }
            }
        })
    }
    
    @IBAction func switchWasToggled(_ sender: Any) {
        if switchBtn.isOn{
            pickupModeLbl.text = "Pick-up modus aan"
            appDelegate.MenuContainerVC.toggleMenuLeftPanel()
            DataService.instance.REF_DRIVERS.child(currentUserId!).updateChildValues(["isPickupModeEnabled" : true])
        } else{
            pickupModeLbl.text = "Pick-up modus uit"
            appDelegate.MenuContainerVC.toggleMenuLeftPanel()
            DataService.instance.REF_DRIVERS.child(currentUserId!).updateChildValues(["isPickupModeEnabled" : false])
        }
    }
    
    @IBAction func inloggenBtnWasPressed(_ sender: Any) {
        //Access storyboard
        if Auth.auth().currentUser == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let inloggenVC = storyboard.instantiateViewController(withIdentifier: "InloggenVC") as? InloggenVC
            present(inloggenVC!, animated: true, completion: nil)
        } else{
            do{
                try Auth.auth().signOut()
                userImageView.isHidden = true
                userMailLbl.text = ""
                userAccountTypeLbl.text = ""
                userAccountView.isHidden = true
                pickupModeLbl.text = ""
                switchBtn.isHidden = true
                inUitloggenBtn.setTitle("Inloggen", for: .normal)
            } catch let(error){
                print(error)
            }
        }
        
    }
    
}
