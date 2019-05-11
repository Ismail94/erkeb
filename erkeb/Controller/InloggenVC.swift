//
//  InloggenVC.swift
//  erkeb
//
//  Created by Ismail on 27/04/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit
import Firebase

class InloggenVC: UIViewController, UITextFieldDelegate, Alertable {

    
    @IBOutlet weak var mailField: RoundedTextField!
    @IBOutlet weak var wachtwoordField: RoundedTextField!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var aanmeldenBtn: RoundedInloggenButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mailField.delegate = self
        wachtwoordField.delegate = self
        
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
    
    @IBAction func aanmeldenBtnWasPressed(_ sender: Any) {
        
        //Als tekst is in de beide tekst velden dan wordt er verder een variabele hiervan gemaakt
        if mailField.text != nil && wachtwoordField.text != nil{
            aanmeldenBtn.animateButton(shouldLoad: true, withMessage: nil)
            self.view.endEditing(true)
            
            //Variabelen worden hier aangemaakt
            if let mail = mailField.text, let wachtwoord = wachtwoordField.text{
                
                // Functie om de wachtwoord en mail doorsturen naar data
                Auth.auth().signIn(withEmail: mail, password: wachtwoord, completion: {(authResult, error) in
                    if  error == nil {
                        if let user = authResult?.user {
                            if self.segmentedControl.selectedSegmentIndex == 0{
                                let userData = ["provider": user.providerID] as [String: Any]
                                DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: false)
                            } else {
                                let userData = ["provider": user.providerID, "userIsDriver": true, "isPickupModeEnabled": false, "driverIsOnTrip": false] as [String: Any]
                                DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: true)
                            }
                        }
                        print("De gebuiker is met succes ingelogd")
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        if let errorCode = AuthErrorCode(rawValue: error!._code){
                            switch errorCode {
                            case .wrongPassword:
                                self.showAlert("Oei! Uw wachtwoord is verkeerd, probeer opnieuw.")
                            default:
                                self.showAlert("Er is een onverwachte fout opgetreden, probeer opnieuw.")
                            }
                        }
                        //Bepaalde fouten die er kunnen zijn tijdens het inloggen
                        Auth.auth().createUser(withEmail: mail, password: wachtwoord, completion: { (authResult, error) in
                            if error != nil {
                                if let errorCode = AuthErrorCode(rawValue: error!._code) {
                                    switch errorCode{
                                    case .emailAlreadyInUse:
                                        self.showAlert("Dit email adres is al in gebruik, probeer opnieuw.")
                                    case .invalidEmail:
                                        self.showAlert("Uw email adres is ongeldig, probeer opnieuw.")
                                    default:
                                        self.showAlert("Er is een onverwachte fout opgetreden, probeer opnieuw.")
                                    }
                                }
                            } else {
                                    //Als er geen fouten zijn dan ga ik een gebruiker en een bestuurder aanmaken
                                    if let user = authResult?.user {
                                        if self.segmentedControl.selectedSegmentIndex == 0 {
                                            let userData = ["provider": user.providerID] as [String: Any]
                                            DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: false)
                                        } else {
                                            let userData = ["provider": user.providerID, "userIsDriver": true, "isPickupModeEnabled": false, "driverIsOnTrip": false] as [String: Any]
                                            DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: true)
                                        }
                                    }
                                    print("Er werd een nieuwe gebruiker aangemaakt via Firebase")
                                    self.dismiss(animated: true, completion: nil)
                                }
                            })
                        }
                    })
                }
            }
        }
}
