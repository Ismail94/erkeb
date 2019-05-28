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
    
    @IBOutlet weak var profielBtn: UIButton!
    @IBOutlet weak var betalingenBtn: UIButton!
    @IBOutlet weak var erkebFamBtn: UIButton!
    @IBOutlet weak var helpBtn: UIButton!
    
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
        
        //Als je geen acount beschikt dan kan je alleen het inloggen knop zien
        if Auth.auth().currentUser == nil {
            userMailLbl.text = ""
            userAccountTypeLbl.text = ""
            userAccountView.isHidden = true
            userImageView.isHidden = true
            profielBtn.isHidden = true
            betalingenBtn.isHidden = true
            erkebFamBtn.isHidden = true
            helpBtn.isHidden = true
            inUitloggenBtn.setTitle(MSG_INLOGGEN, for: .normal)
        } else {
            userMailLbl.text = Auth.auth().currentUser?.email
            userAccountTypeLbl.text = ""
            userAccountView.isHidden = false
            userImageView.isHidden = false
            profielBtn.isHidden = false
            betalingenBtn.isHidden = false
            erkebFamBtn.isHidden = false
            helpBtn.isHidden = false
            inUitloggenBtn.setTitle(MSG_UITLOGGEN, for: .normal)
        }
    }
    
    //check als het een passagier of een bestuurder het acount gebruikt
    func checkPassagiersEnBestuurders(){
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for snap in snapshot{
                    if snap.key == Auth.auth().currentUser?.uid {
                        self.userAccountTypeLbl.text = ACCOUNT_TYPE_PASSAGIER
                    }
                }
            }
        })
        
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for snap in snapshot {
                    if snap.key == Auth.auth().currentUser?.uid {
                        self.userAccountTypeLbl.text = ACCOUNT_TYPE_BESTUURDER
                        self.switchBtn.isHidden = false
                        
                        let switchStatus = snap.childSnapshot(forPath: ACCOUNT_PICKUP_MODUS_AAN).value as! Bool
                        self.switchBtn.isOn = switchStatus
                        self.pickupModeLbl.isHidden = false
                    }
                }
            }
        })
    }
    
    @IBAction func switchWasToggled(_ sender: Any) {
        if switchBtn.isOn{
            pickupModeLbl.text = MSG_PICKUP_MODUS_AAN
            //als je aan modus switch dan sluit de menu panel zich en opent automatisch de kaart
            appDelegate.MenuContainerVC.toggleMenuLeftPanel()
            DataService.instance.REF_DRIVERS.child(currentUserId!).updateChildValues([ACCOUNT_PICKUP_MODUS_AAN : true])
        } else {
            pickupModeLbl.text = MSG_PICKUP_MODUS_UIT
            appDelegate.MenuContainerVC.toggleMenuLeftPanel()
            DataService.instance.REF_DRIVERS.child(currentUserId!).updateChildValues([ACCOUNT_PICKUP_MODUS_AAN : false])
        }
    }
    
    @IBAction func inloggenBtnWasPressed(_ sender: Any) {
        //Access storyboard
        if Auth.auth().currentUser == nil {
            let storyboard = UIStoryboard(name: MAIN_STORYBOARD, bundle: Bundle.main)
            let inloggenVC = storyboard.instantiateViewController(withIdentifier: VC_INLOGGEN) as? InloggenVC
            present(inloggenVC!, animated: true, completion: nil)
        } else {
            do {
                try Auth.auth().signOut()
                userImageView.isHidden = true
                userMailLbl.text = ""
                userAccountTypeLbl.text = ""
                userAccountView.isHidden = true
                pickupModeLbl.text = ""
                switchBtn.isHidden = true
                profielBtn.isHidden = true
                betalingenBtn.isHidden = true
                erkebFamBtn.isHidden = true
                helpBtn.isHidden = true
                inUitloggenBtn.setTitle(MSG_INLOGGEN, for: .normal)
            } catch (let error) {
                print(error)
            }
        }
    }
}
