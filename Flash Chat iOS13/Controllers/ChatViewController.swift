//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    
    var messages: [Message] = [
        Message(sender: "1@s.com", body: "Heay!"),
        Message(sender: "1@b.com", body: "Hello!"),
        Message(sender: "1@s.com", body: "Wazza!"),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        
        navigationItem.hidesBackButton = true
        title = K.appName
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        loadMessages()
    }
    
    func loadMessages(){
        
        db.collection(K.FStore.collectionName).order(by: K.FStore.dateField ).addSnapshotListener({ (querySnapshot, error) in
            if let e = error{
                print("Error while reading from Fire Store: \(e)")
            }else{
                if let snapdocs = querySnapshot?.documents{
                    self.messages = []
                    for doc in snapdocs{
                        let d = doc.data()
                        if let sender = d[K.FStore.senderField] as? String,
                           let body = d[K.FStore.bodyField] as? String{
                            let m = Message(sender: sender, body: body)
                            self.messages.append(m)
                            
                            DispatchQueue.main.async{
                                self.tableView.reloadData()
                                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                            }
                        }
                    }
                    
                }
            }
        })
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        
        if let messageBody = messageTextfield.text, let messageSender = Auth.auth().currentUser?.email{
            let m = Message(sender: messageSender, body: messageBody)
            let col = K.FStore.collectionName
            let doc = [
                K.FStore.senderField: messageSender,
                K.FStore.bodyField: messageBody,
                K.FStore.dateField: Date().timeIntervalSince1970
            ] as [String : Any]
            db.collection(col).addDocument(data: doc) { error in
                if let e = error{
                    print(e)
                }else{
                    print("Success saving data")
                    DispatchQueue.main.async {
                        self.messageTextfield.text = ""
                    }                    
                }
            }
        }
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        let firebaseAuth = Auth.auth()
        
        do {
            try firebaseAuth.signOut()
            navigationController?.popViewController(animated: true)
        }catch let signOutError as NSError{
            print("Error signing out: %@", signOutError)
        }
    }
    
}


extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier:  K.cellIdentifier, for: indexPath) as! MessageCell
        cell.label.text = messages[indexPath.row].body

        if message.sender == Auth.auth().currentUser?.email{
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
            cell.label.textColor = UIColor(named: K.BrandColors.purple)
        }else{
            cell.leftImageView.isHidden = false
            cell.rightImageView.isHidden = true
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.purple)
            cell.label.textColor = UIColor(named: K.BrandColors.lightPurple)
        }
        
        return cell
    }
    
    
}

