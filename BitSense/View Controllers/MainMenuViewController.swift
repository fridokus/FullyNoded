//
//  MainMenuViewController.swift
//  BitSense
//
//  Created by Peter on 08/09/18.
//  Copyright © 2018 Fontaine. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import AES256CBC

class MainMenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var hashrateString = String()
    var version = String()
    var incomingCount = Int()
    var outgoingCount = Int()
    var isPruned = Bool()
    var isTestnet = Bool()
    var rawTxUnsigned = String()
    var rawTxSigned = String()
    var totalInputs = Double()
    var totalOutputs = Double()
    var total = Double()
    var tx = String()
    var currentBlock = Int()
    var newFee = Double()
    var amount = String()
    var address = String()
    var inputs = ""
    var changeAddress = String()
    var changeAmount = Double()
    var inputArray = [Any]()
    var utxoTxId = String()
    var utxoVout = Int()
    var recipientAddress = ""
    let syncStatusLabel = UILabel()
    var latestBlockHeight = Int()
    let descriptionLabel = UILabel()
    let qrView = UIImageView()
    var tapQRGesture = UITapGestureRecognizer()
    var tapAddressGesture = UITapGestureRecognizer()
    var addressString = String()
    var qrCode = UIImage()
    let label = UILabel()
    let subview = UIView()
    let receiveButton = UIButton()
    let settingsButton = UIButton()
    let searchButton = UIButton()
    let qrButton = UIButton()
    var balance = Double()
    let balancelabel = UILabel()
    let searchBar = UISearchBar()
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.regular))
    let receiveBlurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.regular))
    let unconfirmedBalanceLabel = UILabel()
    var activityIndicator:UIActivityIndicatorView!
    var blurActivityIndicator:UIActivityIndicatorView!
    var transactionArray = [[String: Any]]()
    @IBOutlet var mainMenu: UITableView!
    var refresher: UIRefreshControl!
    let rawButton = UIButton()
    var isUsingSSH = Bool()
    var ssh:SSHService!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("main menu")
        
        mainMenu.delegate = self
        searchBar.delegate = self
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(self.refresh), for: UIControlEvents.valueChanged)
        mainMenu.addSubview(refresher)
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x: self.view.center.x - 25, y: self.view.center.y - 25, width: 50, height: 50))
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        activityIndicator.isUserInteractionEnabled = true
        view.addSubview(self.activityIndicator)
        mainMenu.tableFooterView = UIView(frame: .zero)
        activityIndicator.startAnimating()
        addBalanceLabel()
        addReceiveButton()
        refresh()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
            
        case "createRaw":
            
            if let vc = segue.destination as? CreateRawTxViewController {
                
                vc.ssh = SSHService.sharedInstance
                vc.isUsingSSH = self.isUsingSSH
                vc.spendable = self.balance
                
            }
            
        case "goReceive":
            
            if let vc = segue.destination as? InvoiceViewController {
             
                vc.ssh = SSHService.sharedInstance
                vc.isUsingSSH = self.isUsingSSH
                
            }
            
        case "importPrivKey":
            
            if let vc = segue.destination as? ImportPrivKeyViewController {
                
                vc.ssh = SSHService.sharedInstance
                vc.isUsingSSH = self.isUsingSSH
                vc.isPruned = self.isPruned
                
            }
            
        default:
            
            break
            
        }
        
    }
    
    func getLatestBlock(isMainnet: Bool) {
        print("getLatestBlock")
        
        var urlToUse:NSURL!
        
       if isMainnet {
            
            urlToUse = NSURL(string: "https://blockchain.info/latestblock")
            
       } else {
        
            urlToUse = NSURL(string: "https://testnet.blockchain.info/latestblock")
        }
        
            
            let task = URLSession.shared.dataTask(with: urlToUse as URL) { (data, response, error) -> Void in
                
                do {
                    
                    if error != nil {
                        
                        print(error as Any)
                        self.removeSpinner()
                        DispatchQueue.main.async {
                            displayAlert(viewController: self, title: "Error", message: "\(String(describing: error))")
                        }
                        
                    } else {
                        
                        if let urlContent = data {
                            
                            do {
                                
                                let jsonAddressResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                                
                                if let heightCheck = jsonAddressResult["height"] as? Int {
                                    
                                    if !self.isUsingSSH {
                                        
                                        self.latestBlockHeight = heightCheck
                                        let percentage = (self.currentBlock * 100) / heightCheck
                                        let percentageString = "\(percentage)% Synced"
                                        DispatchQueue.main.async {
                                            self.addSyncStatusLabel(title: percentageString)
                                            UIView.animate(withDuration: 0.5, animations: {
                                                self.syncStatusLabel.alpha = 1
                                            })
                                        }
                                        self.executeNodeCommand(method: BTC_CLI_COMMAND.listtransactions.rawValue, param: "")
                                        
                                    } else {
                                        
                                        let percentage = (self.currentBlock * 100) / heightCheck
                                        let percentageString = "\(percentage)% Synced"
                                        DispatchQueue.main.async {
                                            self.addSyncStatusLabel(title: percentageString)
                                            UIView.animate(withDuration: 0.5, animations: {
                                                self.syncStatusLabel.alpha = 1
                                            })
                                        }
                                    }
                                    
                               }
                                
                            } catch {
                                
                                print("JSon processing failed")
                                
                            }
                        }
                    }
                }
            }
            
            task.resume()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 2
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            
            return 1
            
        } else if section == 1 {
            
            if transactionArray.count > 0 {
                
                return transactionArray.count
                
            } else {
                
                return 1
                
            }
            
        } else {
            
            return 0
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "NodeInfo", for: indexPath)
            let network = cell.viewWithTag(1) as! UILabel
            let pruned = cell.viewWithTag(2) as! UILabel
            let connections = cell.viewWithTag(3) as! UILabel
            let version = cell.viewWithTag(4) as! UILabel
            let hashRate = cell.viewWithTag(5) as! UILabel
            
            if self.hashrateString != "" {
                
                if self.isPruned {
                    
                    pruned.text = "True"
                    
                } else if !self.isPruned {
                    
                    pruned.text = "False"
                }
                
                if self.isTestnet {
                    
                    network.text = "Testnet"
                    
                } else if !self.isTestnet {
                    
                    network.text = "Mainnet"
                    
                }
                
                connections.text = "\(outgoingCount) outgoing / \(incomingCount) incoming"
                version.text = self.version
                hashRate.text = self.hashrateString + " " + "h/s"
                
            }
            
            return cell
            
        } else {
            
            if self.transactionArray.count == 0 {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                cell.selectionStyle = .none
                let label = cell.viewWithTag(1) as! UILabel
                label.adjustsFontSizeToFitWidth = true
                return cell
                
            } else if (indexPath.row > self.transactionArray.count - 1) {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "MainMenuCell", for: indexPath)
                cell.selectionStyle = .none
                
                return cell
                
            } else {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "MainMenuCell", for: indexPath)
                cell.selectionStyle = .none
                let addressLabel = cell.viewWithTag(1) as! UILabel
                let amountLabel = cell.viewWithTag(2) as! UILabel
                let confirmationsLabel = cell.viewWithTag(3) as! UILabel
                let labelLabel = cell.viewWithTag(4) as! UILabel
                let dateLabel = cell.viewWithTag(5) as! UILabel
                let feeLabel = cell.viewWithTag(6) as! UILabel
                addressLabel.text = self.transactionArray[indexPath.row]["address"] as? String
                var suffix = String()
                if !isTestnet {
                    suffix = "BTC"
                } else {
                    suffix = "tBTC"
                }
                amountLabel.text = (self.transactionArray[indexPath.row]["amount"] as! String) + " " + suffix
                confirmationsLabel.text = (self.transactionArray[indexPath.row]["confirmations"] as! String) + " " + "CONFS"
                labelLabel.text = self.transactionArray[indexPath.row]["label"] as? String
                dateLabel.text = self.transactionArray[indexPath.row]["date"] as? String
                if self.transactionArray[indexPath.row]["fee"] as? String != "" {
                    feeLabel.text = "Fee:" + " " + (self.transactionArray[indexPath.row]["fee"] as! String)
                }
                
                if self.transactionArray[indexPath.row]["abandoned"] as? Bool == true {
                    
                    cell.backgroundColor = UIColor.red
                    
                }
                
                return cell
                
            }
            
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {
            
            let cell = tableView.cellForRow(at: indexPath)!
            
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2, animations: {
                    cell.alpha = 0
                }) { _ in
                    UIView.animate(withDuration: 0.2, animations: {
                        cell.alpha = 1
                    })
                }
            }
            
            let selectedTx = self.transactionArray[indexPath.row]
            let rbf = selectedTx["rbf"] as! String
            let txID = selectedTx["txID"] as! String
            self.tx = txID
            let replacedBy = selectedTx["replacedBy"] as! String
            let confirmations = selectedTx["confirmations"] as! String
            let amount = selectedTx["amount"] as! String
            let address = selectedTx["address"] as! String
            
            UIPasteboard.general.string = txID
            
            if rbf == "yes" && replacedBy == "" && amount.hasPrefix("-") && !confirmations.hasPrefix("-") {
                
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Bump the fee", message: "This will create a new transaction with an increased fee and will invalidate the original.", preferredStyle: .actionSheet)
                    
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Bump the fee", comment: ""), style: .default, handler: { (action) in
                        
                        if !self.isUsingSSH {
                            
                            self.executeNodeCommand(method: BTC_CLI_COMMAND.bumpfee.rawValue, param: "\"\(txID)\"")
                            
                        } else {
                            
                            self.bumpFee(ssh: self.ssh)
                            
                        }
                        
                    }))
                    
                    /*alert.addAction(UIAlertAction(title: "Abandon Transaction", style: .default, handler: { (action) in
                     
                     if !self.isUsingSSH {
                     
                     self.executeNodeCommand(method: BTC_CLI_COMMAND.abandontransaction.rawValue, param: "\"\(txID)\"")
                     
                     } else {
                     
                     self.abandonTx(ssh: self.ssh)
                     
                     }
                     
                     }))*/
                    
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action) in }))
                    
                    //self.present(alert, animated: true, completion: nil)
                    alert.popoverPresentationController?.sourceView = self.view
                    
                    self.present(alert, animated: true) {
                        
                    }
                }
                
            } else if confirmations == "0" && !amount.hasPrefix("-") {
                
                print("CPFP")
                //enable CPFP
                /*let oldFeeString = selectedTx["fee"] as! String
                 print("oldFeeString = \(oldFeeString)")
                 if let oldFeeInt = Int(oldFeeString) {
                 
                 self.newFee = oldFeeInt * 2
                 print("oldFee = \(oldFeeInt)")
                 print("newFee = \(self.newFee)")
                 
                 }*/
                self.amount = amount
                self.address = address
                self.recipientAddress = address
                /*if !isUsingSSH {
                 self.executeNodeCommand(method: BTC_CLI_COMMAND.getrawtransaction.rawValue, param: "\"\(txID)\"")
                 } else {
                 self.getrawtransaction(txID: txID, ssh: ssh)
                 }*/
                
                
            } else {
                
                let textToShare = [txID]
                let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.view
                
                self.present(activityViewController, animated: true) {
                    
                }
            }
            
        }
        
    }
    
    func addReceiveButton() {
        
        DispatchQueue.main.async {
            self.receiveButton.removeFromSuperview()
            self.receiveButton.showsTouchWhenHighlighted = true
            self.receiveButton.setImage(UIImage(named: "whitePlus.png"), for: .normal)
            self.receiveButton.alpha = 0
            self.receiveButton.addTarget(self, action: #selector(self.receive), for: .touchUpInside)
            self.view.addSubview(self.receiveButton)
            
            self.rawButton.removeFromSuperview()
            self.rawButton.showsTouchWhenHighlighted = true
            self.rawButton.setImage(UIImage(named: "whiteSubtract"), for: .normal)
            self.rawButton.alpha = 0
            self.rawButton.addTarget(self, action: #selector(self.createRaw), for: .touchUpInside)
            self.view.addSubview(self.rawButton)
        }
        
    }
    
    @objc func createRaw() {
        
        self.performSegue(withIdentifier: "createRaw", sender: self)
        
    }
    
   @objc func refresh() {
    
        mainMenu.isUserInteractionEnabled = false
        transactionArray.removeAll()
        addBalanceLabel()
    
        UIView.animate(withDuration: 0.2) {
        
            self.syncStatusLabel.alpha = 0
        
        }
    
        if UserDefaults.standard.string(forKey: "sshPassword") != nil {
        
            isUsingSSH = true
        
        } else {
        
            isUsingSSH = false
        
        }
    
        if isUsingSSH {
            
            //let ssh = SSHService.sharedInstance
            ssh = SSHService.sharedInstance
            
            let queue = DispatchQueue(label: "com.FullyNoded.getInitialNodeConnection")
            queue.async {
                
                self.ssh.connect { (success, error) in
                    
                    if success {
                        
                        print("connected succesfully")
                        self.getBlockchainInfo()
                        
                    } else {
                        
                        print("ssh fail")
                        print("error = \(String(describing: error))")
                        self.removeSpinner()
                        
                        if error != nil {
                            
                            displayAlert(viewController: self, title: "Error", message: String(describing: error!))
                            
                        } else {
                            
                            displayAlert(viewController: self, title: "Error", message: "Unable to connect")
                            
                        }
                        
                        
                    }
                    
                }
                
            }
            
        } else {
            
           self.executeNodeCommand(method: BTC_CLI_COMMAND.getblockchaininfo.rawValue, param: "")
            
        }
    
    }
    
    func getBlockchainInfo() {
        
        let queue = DispatchQueue(label: "com.FullyNoded.getInitialNodeConnection")
        queue.async {
            self.ssh.execute(command: BTC_CLI_COMMAND.getblockchaininfo, params: "", response: { (result, error) in
                if error != nil {
                    print("error getblockchaininfo")
                    
                    DispatchQueue.main.async {
                        
                        self.mainMenu.isUserInteractionEnabled = true
                        self.removeSpinner()
                        displayAlert(viewController: self, title: "Error", message: "We connected to your server succesfully but it looks like Bitcoin Core may not be running. \n\nError description: \(error!.debugDescription)")
                        
                    }
                    
                } else {
                    //print("result = \(String(describing: result))")
                    if let dict = result as? NSDictionary {
                        
                        if let currentblockheight = dict["blocks"] as? Int {
                            self.currentBlock = currentblockheight
                        }
                        
                        if let chain = dict["chain"] as? String {
                            if chain == "test" {
                                self.isTestnet = true
                                self.getLatestBlock(isMainnet: false)
                                self.listTransactions()
                            } else {
                                self.isTestnet = false
                                self.getLatestBlock(isMainnet: true)
                                self.listTransactions()
                            }
                        }
                        
                        if let pruned = dict["pruned"] as? Bool {
                            
                            if pruned {
                             
                                self.isPruned = true
                                
                            } else {
                                
                                self.isPruned = false
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            })
            
        }
        
    }
    
    func getPeerInfoSSH() {
        
        let queue = DispatchQueue(label: "com.FullyNoded.getInitialNodeConnection")
        queue.async {
     
            self.ssh.execute(command: BTC_CLI_COMMAND.getpeerinfo, params: "", response: { (result, error) in
     
                if error != nil {
     
                    print("error getblockchaininfo \(error)")
     
                } else {
     
                    print("result = \(String(describing: result))")
     
                    if let peers = result as? NSArray {
                        
                        self.incomingCount = 0
                        self.outgoingCount = 0
                        
                        for peer in peers {
                            
                            let peerDict = peer as! NSDictionary
                            
                            let incoming = peerDict["inbound"] as! Bool
                            
                            if incoming {
                            
                                print("incoming")
                                self.incomingCount = self.incomingCount + 1
                                
                            } else {
                                
                                print("outgoing")
                                self.outgoingCount = self.outgoingCount + 1
                                
                            }
                            
                        }
                        
                        self.getNetworkInfoSSH()
                        /*DispatchQueue.main.async {
                            self.removeSpinner()
                            self.mainMenu.reloadData()
                        }*/
                        
                    }
                    
                }
                
            })
            
        }
        
    }
    
    func getNetworkInfoSSH() {
        
        let queue = DispatchQueue(label: "com.FullyNoded.getInitialNodeConnection")
        queue.async {
            
            self.ssh.execute(command: BTC_CLI_COMMAND.getnetworkinfo, params: "", response: { (result, error) in
                
                if error != nil {
                    
                    print("error getblockchaininfo \(String(describing: error))")
                    
                } else {
                    
                    print("result = \(String(describing: result))")
                    
                    if let networkinfo = result as? NSDictionary {
                        
                        self.version = (networkinfo["subversion"] as! String).replacingOccurrences(of: "/", with: "")
                        
                        self.getMiningInfoSSH()
                        
                    }
                    
                }
                
            })
            
        }
        
    }
    
    func getMiningInfoSSH() {
        
        let queue = DispatchQueue(label: "com.FullyNoded.getInitialNodeConnection")
        queue.async {
            
            self.ssh.execute(command: BTC_CLI_COMMAND.getmininginfo, params: "", response: { (result, error) in
                
                if error != nil {
                    
                    print("error getblockchaininfo \(String(describing: error))")
                    
                } else {
                    
                    print("result = \(String(describing: result))")
                    
                    if let networkinfo = result as? NSDictionary {
                        
                        self.hashrateString = (networkinfo["networkhashps"] as! Double).withCommas()
                        
                        DispatchQueue.main.async {
                            self.removeSpinner()
                            self.mainMenu.reloadData()
                        }
                        
                    }
                    
                }
                
            })
            
        }
        
    }
    
    func abandonTx(ssh: SSHService) {
        
        let queue = DispatchQueue(label: "com.FullyNoded.getInitialNodeConnection")
        queue.async {
            
            //ssh.execute(command: BTC_COMMAND.abandontransaction, params: "\"\(self.tx)\"", response: { (result, error) in
            
            ssh.executeStringResponse(command: BTC_CLI_COMMAND.abandontransaction, params: "\"\(self.tx)\"", response: { (result, error) in
               
                
                if error != nil {
                    
                    print("error abandontransaction")
                    displayAlert(viewController: self, title: "Error", message: "\(error)")
                    
                } else {
                    
                    print("result = \(String(describing: result))")
                    
                    if let _ = result as? Any {
                        
                        DispatchQueue.main.async {
                            self.refresh()
                        }
                        
                        displayAlert(viewController: self, title: "Success", message: "You abandonded the transaction")
                        
                    }
                    
                }
                
            })
            
        }
        
    }
    
    func bumpFee(ssh: SSHService) {
        
        let queue = DispatchQueue(label: "com.FullyNoded.getInitialNodeConnection")
        queue.async {
            
            ssh.execute(command: BTC_CLI_COMMAND.bumpfee, params: "\"\(self.tx)\"", response: { (result, error) in
                
                if error != nil {
                    
                    print("error bumpfee")
                    
                } else {
                    
                    print("result = \(String(describing: result))")
                    
                    if let dict = result as? NSDictionary {
                        
                        let originalFee = dict["origfee"] as! Double
                        let newFee = dict["fee"] as! Double
                        
                        DispatchQueue.main.async {
                            self.refresh()
                        }
                        
                        displayAlert(viewController: self, title: "Success", message: "You increased the fee from \(originalFee.avoidNotation) to \(newFee.avoidNotation)")
                        
                    }
                    
                }
                
            })
            
        }
        
    }
    
    func listTransactions() {
        
        let queue = DispatchQueue(label: "com.FullyNoded.getInitialNodeConnection")
        queue.async {
            self.ssh.execute(command: BTC_CLI_COMMAND.listtransactions, params: "", response: { (result, error) in
                if error != nil {
                    print("error listtransactions = \(String(describing: error))")
                } else {
                    //print("result = \(String(describing: result))")
                    if let transactionsCheck = result as? NSArray {
                        
                        //self.getBalance()
                        
                        for item in transactionsCheck {
                            
                            if let transaction = item as? NSDictionary {
                                
                                //print("transaction = \(transaction)")
                                
                                var label = String()
                                var fee = String()
                                var replaced_by_txid = String()
                                
                                let address = transaction["address"] as! String
                                let amount = transaction["amount"] as! Double
                                let amountString = amount.avoidNotation
                                let confirmations = String(transaction["confirmations"] as! Int)
                                if let replaced_by_txid_check = transaction["replaced_by_txid"] as? String {
                                    replaced_by_txid = replaced_by_txid_check
                                }
                                if let labelCheck = transaction["label"] as? String {
                                    label = labelCheck
                                }
                                if let feeCheck = transaction["fee"] as? Double {
                                    fee = feeCheck.avoidNotation
                                }
                                let secondsSince = transaction["time"] as! Double
                                let rbf = transaction["bip125-replaceable"] as! String
                                let txID = transaction["txid"] as! String
                                
                                let date = Date(timeIntervalSince1970: secondsSince)
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "MMM-dd-yyyy HH:mm"
                                let dateString = dateFormatter.string(from: date)
                                
                                self.transactionArray.append(["address": address, "amount": amountString, "confirmations": confirmations, "label": label, "date": dateString, "rbf": rbf, "txID": txID, "fee": fee, "replacedBy": replaced_by_txid])
                                
                            }
                        }
                        
                        
                        
                        DispatchQueue.main.async {
                            self.transactionArray = self.transactionArray.reversed()
                            self.mainMenu.reloadData()
                            self.mainMenu.isUserInteractionEnabled = true
                            UIView.animate(withDuration: 0.5) {
                                self.mainMenu.alpha = 1
                            }
                        }
                        
                        self.getBalance()
                    }
                }
            })
        }
    }
    
    /*func getrawtransaction(txID: String, ssh: SSHService) {
        
        let queue = DispatchQueue(label: "com.FullyNoded.getInitialNodeConnection")
        queue.async {//DispatchQueue.main.async {
            ssh.executeStringResponse(command: BTC_COMMAND.getrawtransaction, params: "\(txID)", response: { (result, error) in
                if error != nil {
                    print("error getrawtransaction = \(String(describing: error))")
                } else {
                    print("result = \(String(describing: result))")
                    if let rw = result as? String {
                        print("raw transaction result = \(rw)")
                        self.decodeRawTransaction(raw: rw, ssh: ssh)
                    }
                }
            })
        }
        
    }*/
    
    /*func decodeRawTransaction(raw: String, ssh: SSHService) {
        
        let queue = DispatchQueue(label: "com.FullyNoded.getInitialNodeConnection")
        queue.async {//DispatchQueue.main.async {
            ssh.execute(command: BTC_COMMAND.decoderawtransaction, params: "\"\(raw)\"", response: { (result, error) in
                if error != nil {
                    print("error decoderawtransaction = \(String(describing: error))")
                } else {
                    //print("result = \(String(describing: result))")
                    
                    if let decodedTx = result as? NSDictionary {
                        DispatchQueue.main.async {
                            //print("decodedTx = \(decodedTx)")
                            
                            //self.parseDecodedTxCPFP(decodedTx: decodedTx)
                        }
                    }
                }
            })
        }
        
        
    }*/
    
    func getBalance() {
        print("getBalance")
        
        let queue = DispatchQueue(label: "com.FullyNoded.getInitialNodeConnection")
        queue.async {//DispatchQueue.main.async {
            self.ssh.executeStringResponse(command: BTC_CLI_COMMAND.getbalance, params: "", response: { (result, error) in
                if error != nil {
                    print("error getbalance = \(String(describing: error))")
                } else {
                    //print("result = \(String(describing: result))")
                    if let balanceCheck = result as? String {
                        self.balance = Double(balanceCheck)!
                        DispatchQueue.main.async {
                            if !self.isTestnet {
                                self.balancelabel.text = "\(self.balance.avoidNotation) BTC"
                            } else {
                                self.balancelabel.text = "\(self.balance.avoidNotation) tBTC"
                            }
                            self.getUnconfirmedBalance()
                        }
                    }
                }
            })
        }
    }
    
    func getUnconfirmedBalance() {
        
        let queue = DispatchQueue(label: "com.FullyNoded.getInitialNodeConnection")
        queue.async {
            self.ssh.executeStringResponse(command: BTC_CLI_COMMAND.getunconfirmedbalance, params: "", response: { (result, error) in
                if error != nil {
                    print("error getunconfirmedbalance = \(String(describing: error))")
                } else {
                    //print("result = \(String(describing: result))")
                    if let unconfirmedBalanceCheck = result as? String {
                        let unconfirmedBalance = Double(unconfirmedBalanceCheck)!
                        if unconfirmedBalance != 0.0 || unconfirmedBalance != 0 {
                            DispatchQueue.main.async {
                                
                                if !self.isTestnet {
                                    self.unconfirmedBalanceLabel.text = "\(unconfirmedBalance.avoidNotation) BTC Unconfirmed"
                                } else {
                                    self.unconfirmedBalanceLabel.text = "\(unconfirmedBalance.avoidNotation) tBTC Unconfirmed"
                                }
                                
                                //self.removeSpinner()
                                UIView.animate(withDuration: 0.5, animations: {
                                    self.balancelabel.alpha = 1
                                    self.qrButton.alpha = 1
                                    self.receiveButton.alpha = 1
                                    self.rawButton.alpha = 1
                                    self.searchButton.alpha = 1
                                    self.unconfirmedBalanceLabel.alpha = 1
                                })
                            }
                        } else {
                            DispatchQueue.main.async {
                                if !self.isTestnet {
                                    self.unconfirmedBalanceLabel.text = "0 BTC Unconfirmed"
                                } else {
                                    self.unconfirmedBalanceLabel.text = "0 tBTC Unconfirmed"
                                }
                                UIView.animate(withDuration: 0.5, animations: {
                                    self.balancelabel.alpha = 1
                                    self.qrButton.alpha = 1
                                    self.receiveButton.alpha = 1
                                    self.rawButton.alpha = 1
                                    self.searchButton.alpha = 1
                                    self.unconfirmedBalanceLabel.alpha = 1
                                })
                                //self.removeSpinner()
                            }
                        }
                        
                        self.getPeerInfoSSH()
                    }
                }
            })
        }
    }
    
    func addSyncStatusLabel(title: String) {
        
        syncStatusLabel.removeFromSuperview()
        syncStatusLabel.text = title
        syncStatusLabel.font = UIFont.init(name: "HelveticaNeue-Light", size: 13)
        syncStatusLabel.alpha = 0
        syncStatusLabel.textColor = UIColor.white
        syncStatusLabel.textAlignment = .left
        view.addSubview(syncStatusLabel)
        
    }
    
    func addBalanceLabel() {
        
        balancelabel.removeFromSuperview()
        unconfirmedBalanceLabel.removeFromSuperview()
        settingsButton.setImage(UIImage(named: "whiteSettings.png"), for: .normal)
        settingsButton.addTarget(self, action: #selector(self.renewCredentials), for: .touchUpInside)
        view.addSubview(settingsButton)
        balancelabel.font = UIFont.init(name: "HelveticaNeue", size: 27)
        balancelabel.textColor = UIColor.white
        balancelabel.textAlignment = .left
        balancelabel.adjustsFontSizeToFitWidth = true
        balancelabel.alpha = 0
        view.addSubview(balancelabel)
        
        unconfirmedBalanceLabel.font = UIFont.init(name: "HelveticaNeue-Light", size: 13)
        unconfirmedBalanceLabel.textColor = UIColor.white
        unconfirmedBalanceLabel.textAlignment = .left
        unconfirmedBalanceLabel.adjustsFontSizeToFitWidth = true
        unconfirmedBalanceLabel.alpha = 0
        view.addSubview(unconfirmedBalanceLabel)
    }
    
    override func viewWillLayoutSubviews() {
        
        let footerMaxY = self.mainMenu.frame.maxY
        let modelName = UIDevice.modelName
        print("model = \(modelName)")
        
        switch modelName {
            
        case "Simulator iPhone X",
             "iPhone X",
             "Simulator iPhone XS",
             "Simulator iPhone XR",
             "Simulator iPhone XS Max",
             "iPhone XS",
             "iPhone XR",
             "iPhone XS Max",
             "Simulator iPhone11,8",
             "iPhone11,8",
             "Simulator iPhone11,2",
             "iPhone11,2",
             "Simulator iPhone11,4",
             "iPhone11,4":
            
            self.balancelabel.frame = CGRect(x: 10, y: 35, width: self.view.frame.width - 100, height: 22)
            self.unconfirmedBalanceLabel.frame = CGRect(x: 11, y: self.balancelabel.frame.maxY, width: view.frame.width - 100, height: 15)
            self.syncStatusLabel.frame = CGRect(x: 10, y: unconfirmedBalanceLabel.frame.maxY, width: 100, height: 15)
            self.settingsButton.frame = CGRect(x: self.view.frame.maxX - 40, y: 33, width: 40, height: 40)
            
        default:
            
            self.settingsButton.frame = CGRect(x: self.view.frame.maxX - 50, y: 18, width: 40, height: 40)
            self.balancelabel.frame = CGRect(x: 10, y: 23, width: self.view.frame.width - 100, height: 22)
            self.syncStatusLabel.frame = CGRect(x: 10, y: unconfirmedBalanceLabel.frame.maxY, width: 100, height: 15)
            self.unconfirmedBalanceLabel.frame = CGRect(x: 11, y: balancelabel.frame.maxY + 5, width: view.frame.width - 100, height: 15)
            
        }
        
        receiveButton.frame = CGRect(x: 15, y: footerMaxY + ((view.frame.maxY - footerMaxY) / 2) - 15, width: 30, height: 30)
        rawButton.frame = CGRect(x: view.frame.maxX - 45, y: footerMaxY + ((view.frame.maxY - footerMaxY) / 2) - 15, width: 30, height: 30)
        
    }
    
    func nodeCommand(command: String) {
        
        switch command {
        case "getBalance": self.executeNodeCommand(method: BTC_CLI_COMMAND.getbalance.rawValue, param: "")
        default:
            break
        }
        
    }
    
    func savePassword(password: String) {
        
        let stringToSave = self.encryptKey(keyToEncrypt: password)
        UserDefaults.standard.set(stringToSave, forKey: "NodePassword")
        
    }
    
    func saveIPAdress(ipAddress: String) {
        
        let stringToSave = self.encryptKey(keyToEncrypt: ipAddress)
        UserDefaults.standard.set(stringToSave, forKey: "NodeIPAddress")
        
    }
    
    func savePort(port: String) {
        
        let stringToSave = self.encryptKey(keyToEncrypt: port)
        UserDefaults.standard.set(stringToSave, forKey: "NodePort")
    }
    
    func saveUsername(username: String) {
        
        let stringToSave = self.encryptKey(keyToEncrypt: username)
        UserDefaults.standard.set(stringToSave, forKey: "NodeUsername")
        
    }
    
    func encryptKey(keyToEncrypt: String) -> String {
        
        let password = KeychainWrapper.standard.string(forKey: "AESPassword")!
        let encryptedkey = AES256CBC.encryptString(keyToEncrypt, password: password)!
        return encryptedkey
        
    }
    
    func executeNodeCommand(method: String, param: Any) {
        print("executeNodeCommand")
        
        var nodeUsername = ""
        var nodePassword = ""
        var ip = ""
        var port = ""
        var credentialsComplete = Bool()
        
        func decrypt(item: String) -> String {
            
            var decrypted = ""
            if let password = KeychainWrapper.standard.string(forKey: "AESPassword") {
                if let decryptedCheck = AES256CBC.decryptString(item, password: password) {
                    decrypted = decryptedCheck
                }
            }
            return decrypted
        }
        
        if UserDefaults.standard.string(forKey: "NodeUsername") != nil {
           
            nodeUsername = decrypt(item: UserDefaults.standard.string(forKey: "NodeUsername")!)
            credentialsComplete = true
            
        } else {
            
            credentialsComplete = false
        }
        
        if UserDefaults.standard.string(forKey: "NodePassword") != nil {
            
            nodePassword = decrypt(item: UserDefaults.standard.string(forKey: "NodePassword")!)
            credentialsComplete = true
            
        } else {
            
            credentialsComplete = false
        }
        
        if UserDefaults.standard.string(forKey: "NodeIPAddress") != nil {
            
            ip = decrypt(item: UserDefaults.standard.string(forKey: "NodeIPAddress")!)
            credentialsComplete = true
            
        } else {
            
            credentialsComplete = false
        }
        
        if UserDefaults.standard.string(forKey: "NodePort") != nil {
            
            port = decrypt(item: UserDefaults.standard.string(forKey: "NodePort")!)
            credentialsComplete = true
            
        } else {
            
            credentialsComplete = false
        }
        
        //if credentialsComplete {
        
        if !credentialsComplete {
            
            port = "18332"
            ip = "46.101.239.249"
            nodeUsername = "bitcoin"
            nodePassword = "password"
            
            savePort(port: port)
            saveIPAdress(ipAddress: ip)
            saveUsername(username: nodeUsername)
            savePassword(password: nodePassword)
            
            displayAlert(viewController: self, title: "Alert", message: "Looks like you have not logged in to your own node yet or incorrectly filled out your credentials, you are connected to our testnet full node so you can play with the app before connecting to your own.\n\nTo connect to your own node tap the settings button and \"Log in to your own node\".\n\nIf you have any issues please email me at bitsenseapp@gmail.com"
            )
        }
        
        print("port = \(port)")
        print("username = \(nodeUsername)")
        print("password = \(nodePassword)")
        print("ip = \(ip)")
            
            let url = URL(string: "http://\(nodeUsername):\(nodePassword)@\(ip):\(port)")
            var request = URLRequest(url: url!)
            request.timeoutInterval = 5
            request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = "{\"jsonrpc\":\"1.0\",\"id\":\"curltest\",\"method\":\"\(method)\",\"params\":[\(param)]}".data(using: .utf8)
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) -> Void in
                
                do {
                    
                    if error != nil {
                        
                        DispatchQueue.main.async {
                            
                            self.mainMenu.isUserInteractionEnabled = true
                            self.removeSpinner()
                            self.showConnectionError()
                            
                        }
                        
                    } else {
                        
                        if let urlContent = data {
                            
                            do {
                                
                                let jsonAddressResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                                
                                if let errorCheck = jsonAddressResult["error"] as? NSDictionary {
                                    
                                    print("error = \(errorCheck.description)")
                                    DispatchQueue.main.async {
                                        self.removeSpinner()
                                        self.mainMenu.isUserInteractionEnabled = true
                                        if let errorMessage = errorCheck["message"] as? String {
                                            displayAlert(viewController: self, title: "Error", message: errorMessage)
                                        }
                                    }
                                    
                                } else {
                                    
                                    if let resultCheck = jsonAddressResult["result"] as? Any {
                                        
                                        switch method {
                                            
                                        case BTC_CLI_COMMAND.abandontransaction.rawValue:
                                            
                                            displayAlert(viewController: self, title: "Success", message: "You have abandoned the transaction!")
                                                
                                            
                                        /*case BTC_CLI_COMMAND.getrawchangeaddress.rawValue:
                                            
                                            if let _ = resultCheck as? String {
                                                
                                                let changeAddress = resultCheck as! String
                                                self.inputs = self.inputArray.description
                                                self.inputs = self.inputs.replacingOccurrences(of: "[\"", with: "[")
                                                self.inputs = self.inputs.replacingOccurrences(of: "\"]", with: "]")
                                                self.inputs = self.inputs.replacingOccurrences(of: "\"{", with: "{")
                                                self.inputs = self.inputs.replacingOccurrences(of: "}\"", with: "}")
                                                self.inputs = self.inputs.replacingOccurrences(of: "\\", with: "")
                                                self.executeNodeCommand(method: BTC_CLI_COMMAND.createrawtransaction.rawValue, param: "\(self.inputs), {\"\(self.address)\":\(self.amount),  \"\(self.changeAddress)\": \(self.changeAmount)}")
                                                
                                            }*/
                                            
                                        /*case BTC_CLI_COMMAND.decoderawtransaction.rawValue:
                                            
                                            if let decodedTx = resultCheck as? NSDictionary {
                                                
                                                print("decoded = \(decodedTx)")
                                                //get old fee
                                                
                                            }*/
                                            
                                        /*case BTC_CLI_COMMAND.getrawtransaction.rawValue:
                                            
                                            if let result = resultCheck as? String {
                                                
                                                print("raw transaction result = \(result)")
                                                self.decodeTx(rawTx: result)
                                                
                                            }*/
                                            
                                        case BTC_CLI_COMMAND.getblockchaininfo.rawValue:
                                            
                                            if let result = resultCheck as? NSDictionary {
                                                
                                                if let currentblockheight = result["blocks"] as? Int {
                                                    
                                                    self.currentBlock = currentblockheight
                                                    
                                                    
                                                }
                                                
                                                if let chain = result["chain"] as? String {
                                                    print("chain = \(chain)")
                                                    if chain == "test" {
                                                        self.isTestnet = true
                                                        self.getLatestBlock(isMainnet: false)
                                                    } else {
                                                        self.isTestnet = false
                                                        self.getLatestBlock(isMainnet: true)
                                                    }
                                                }
                                                
                                                if let pruned = result["pruned"] as? Bool {
                                                    
                                                    if pruned {
                                                        
                                                        self.isPruned = true
                                                        
                                                    } else {
                                                        
                                                        self.isPruned = false
                                                        
                                                    }
                                                    
                                                }
                                            }
                                            
                                        case BTC_CLI_COMMAND.bumpfee.rawValue:
                                            
                                            if let result = resultCheck as? NSDictionary {
                                                
                                                let originalFee = result["origfee"] as! Double
                                                let newFee = result["fee"] as! Double
                                                DispatchQueue.main.async {
                                                    self.refresh()
                                                }
                                                
                                                displayAlert(viewController: self, title: "Success", message: "You increased the fee from \(originalFee.avoidNotation) to \(newFee.avoidNotation)")
                                                
                                            }
                                            
                                        case BTC_CLI_COMMAND.getunconfirmedbalance.rawValue:
                                            
                                            if let unconfirmedBalance = resultCheck as? Double {
                                                
                                                if unconfirmedBalance != 0.0 || unconfirmedBalance != 0 {
                                                    
                                                    DispatchQueue.main.async {
                                                        
                                                        if !self.isTestnet {
                                                            self.unconfirmedBalanceLabel.text = "\(unconfirmedBalance.avoidNotation) BTC Unconfirmed"
                                                        } else {
                                                            self.unconfirmedBalanceLabel.text = "\(unconfirmedBalance.avoidNotation) tBTC Unconfirmed"
                                                        }
                                                        
                                                        self.removeSpinner()
                                                        
                                                        UIView.animate(withDuration: 0.5, animations: {
                                                            
                                                            self.balancelabel.alpha = 1
                                                            self.qrButton.alpha = 1
                                                            self.receiveButton.alpha = 1
                                                            self.rawButton.alpha = 1
                                                            self.searchButton.alpha = 1
                                                            self.unconfirmedBalanceLabel.alpha = 1
                                                            
                                                        })
                                                    }
                                                    
                                                } else {
                                                    
                                                    DispatchQueue.main.async {
                                                        
                                                        if !self.isTestnet {
                                                            self.unconfirmedBalanceLabel.text = "0 BTC Unconfirmed"
                                                        } else {
                                                            self.unconfirmedBalanceLabel.text = "0 tBTC Unconfirmed"
                                                        }
                                                        
                                                        UIView.animate(withDuration: 0.5, animations: {
                                                            
                                                            self.balancelabel.alpha = 1
                                                            self.qrButton.alpha = 1
                                                            self.receiveButton.alpha = 1
                                                            self.rawButton.alpha = 1
                                                            self.searchButton.alpha = 1
                                                            self.unconfirmedBalanceLabel.alpha = 1
                                                            
                                                        })
                                                        
                                                        self.removeSpinner()
                                                    }
                                                    
                                                }
                                                
                                            }
                                            
                                        case BTC_CLI_COMMAND.getbalance.rawValue:
                                            
                                            if let balanceCheck = resultCheck as? Double {
                                                
                                                self.balance = balanceCheck
                                                
                                                DispatchQueue.main.async {
                                                    
                                                    if !self.isTestnet {
                                                       self.balancelabel.text = "\(balanceCheck.avoidNotation) BTC"
                                                    } else {
                                                        self.balancelabel.text = "\(balanceCheck.avoidNotation) tBTC"
                                                    }
                                                    
                                                    self.executeNodeCommand(method: BTC_CLI_COMMAND.getunconfirmedbalance.rawValue, param: "")
                                                }
                                                
                                            }
                                            
                                        case BTC_CLI_COMMAND.listtransactions.rawValue:
                                            
                                            if let transactionsCheck = resultCheck as? NSArray {
                                                
                                                self.nodeCommand(command: "getBalance")
                                                
                                                for item in transactionsCheck {
                                                    
                                                    if let transaction = item as? NSDictionary {
                                                        
                                                        //print("transaction = \(transaction)")
                                                        
                                                        var label = String()
                                                        var fee = String()
                                                        var replaced_by_txid = String()
                                                        
                                                        let address = transaction["address"] as! String
                                                        let amount = transaction["amount"] as! Double
                                                        let amountString = amount.avoidNotation
                                                        let confirmations = String(transaction["confirmations"] as! Int)
                                                        if let replaced_by_txid_check = transaction["replaced_by_txid"] as? String {
                                                            replaced_by_txid = replaced_by_txid_check
                                                        }
                                                        if let labelCheck = transaction["label"] as? String {
                                                            label = labelCheck
                                                        }
                                                        if let feeCheck = transaction["fee"] as? Double {
                                                            fee = feeCheck.avoidNotation
                                                        }
                                                        let secondsSince = transaction["time"] as! Double
                                                        let rbf = transaction["bip125-replaceable"] as! String
                                                        let txID = transaction["txid"] as! String
                                                        
                                                        let date = Date(timeIntervalSince1970: secondsSince)
                                                        let dateFormatter = DateFormatter()
                                                        dateFormatter.dateFormat = "MMM-dd-yyyy HH:mm"
                                                        let dateString = dateFormatter.string(from: date)
                                                        
                                                        self.transactionArray.append(["address": address, "amount": amountString, "confirmations": confirmations, "label": label, "date": dateString, "rbf": rbf, "txID": txID, "fee": fee, "replacedBy": replaced_by_txid])
                                                        
                                                    }
                                                    
                                                }
                                                
                                                DispatchQueue.main.async {
                                                    self.transactionArray = self.transactionArray.reversed()
                                                    self.mainMenu.reloadData()
                                                    self.mainMenu.isUserInteractionEnabled = true
                                                    UIView.animate(withDuration: 0.5) {
                                                        self.mainMenu.alpha = 1
                                                    }
                                                }
                                                
                                            }
                                            
                                        default: break
                                            
                                        }
                                        
                                    } else {
                                        
                                        print("no results")
                                        self.mainMenu.isUserInteractionEnabled = true
                                        self.removeSpinner()
                                        
                                    }
                                    
                                }
                                
                            } catch {
                                
                                DispatchQueue.main.async {
                                    self.removeSpinner()
                                    self.mainMenu.isUserInteractionEnabled = true
                                    self.refresher.endRefreshing()
                                    self.showConnectionError()
                                }
                                
                            }
                        }
                    }
                }
            }
            
            task.resume()
            
        /*} else {
            
            DispatchQueue.main.async {
                self.removeSpinner()
                self.mainMenu.isUserInteractionEnabled = true
                self.refresher.endRefreshing()
                self.showConnectionError()
            }
        }*/
    }
    
    @objc func receive() {
        
        let alert = UIAlertController(title: NSLocalizedString("Select an option", comment: ""), message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Create Invoice", comment: ""), style: .default, handler: { (action) in
            
            DispatchQueue.main.async {
                
                self.performSegue(withIdentifier: "goReceive", sender: self)
                
            }
            
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Import Private Key", comment: ""), style: .default, handler: { (action) in
            
            DispatchQueue.main.async {
                
                self.performSegue(withIdentifier: "importPrivKey", sender: self)
                
            }
            
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action) in }))
        
        alert.popoverPresentationController?.sourceView = self.view
        
        self.present(alert, animated: true) {
            
        }
        
    }
    
    func removeSpinner() {
        
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.refresher.endRefreshing()
        }
    }
    
    @objc func renewCredentials() {
        
        self.performSegue(withIdentifier: "goToSettings", sender: self)
        
    }
    
    /*func decodeTx(rawTx: String) {
        
        var nodeUsername = ""
        var nodePassword = ""
        var ip = ""
        var port = ""
        var credentialsComplete = Bool()
        
        func decrypt(item: String) -> String {
            
            var decrypted = ""
            if let password = KeychainWrapper.standard.string(forKey: "AESPassword") {
                if let decryptedCheck = AES256CBC.decryptString(item, password: password) {
                    decrypted = decryptedCheck
                }
            }
            return decrypted
        }
        
        if UserDefaults.standard.string(forKey: "NodeUsername") != nil {
            
            nodeUsername = decrypt(item: UserDefaults.standard.string(forKey: "NodeUsername")!)
            credentialsComplete = true
            
        } else {
            
            credentialsComplete = false
        }
        
        if UserDefaults.standard.string(forKey: "NodePassword") != nil {
            
            nodePassword = decrypt(item: UserDefaults.standard.string(forKey: "NodePassword")!)
            credentialsComplete = true
            
        } else {
            
            credentialsComplete = false
        }
        
        if UserDefaults.standard.string(forKey: "NodeIPAddress") != nil {
            
            ip = decrypt(item: UserDefaults.standard.string(forKey: "NodeIPAddress")!)
            credentialsComplete = true
            
        } else {
            
            credentialsComplete = false
        }
        
        if UserDefaults.standard.string(forKey: "NodePort") != nil {
            
            port = decrypt(item: UserDefaults.standard.string(forKey: "NodePort")!)
            credentialsComplete = true
            
        } else {
            
            credentialsComplete = false
        }
        
        if credentialsComplete {
            
            let url = URL(string: "http://\(nodeUsername):\(nodePassword)@\(ip):\(port)")
            var request = URLRequest(url: url!)
            request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = "{\"jsonrpc\":\"1.0\",\"id\":\"curltest\",\"method\":\"\(BTC_CLI_COMMAND.decoderawtransaction.rawValue)\",\"params\":[\("\"\(rawTx)\"")]}".data(using: .utf8)
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) -> Void in
                
                do {
                    
                    if error != nil {
                        DispatchQueue.main.async {
                            self.mainMenu.isUserInteractionEnabled = true
                            self.removeSpinner()
                            self.showConnectionError()
                        }
                        
                    } else {
                        
                        if let urlContent = data {
                            
                            do {
                                
                                let jsonAddressResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                                
                                if let errorCheck = jsonAddressResult["error"] as? NSDictionary {
                                    
                                    print("error = \(errorCheck.description)")
                                    DispatchQueue.main.async {
                                        if let errorMessage = errorCheck["message"] as? String {
                                            displayAlert(viewController: self, title: "Error", message: errorMessage)
                                        }
                                    }
                                    
                                } else {
                                    
                                    if let resultCheck = jsonAddressResult["result"] as? Any {
                                        
                                        if let decodedTx = resultCheck as? NSDictionary {
                                            
                                            print("decoded = \(decodedTx)")
                                            self.parseDecodedTx(decodedTx: decodedTx)
                                        }
                                        
                                    } else {
                                        
                                        print("no results")
                                        
                                        
                                    }
                                    
                                }
                                
                            } catch {
                                
                                DispatchQueue.main.async {
                                    
                                    self.showConnectionError()
                                }
                                
                            }
                        }
                    }
                }
            }
            
            task.resume()
            
        } else {
            
            DispatchQueue.main.async {
                
                self.showConnectionError()
            }
        }
        
        
    }*/
    
    /*func getPrevInputValueForCPFP(txID: String, prevvout: Int) {
        print("getPrevInputValueForCPFP")
        
        DispatchQueue.main.async {
            self.ssh.executeStringResponse(command: BTC_COMMAND.getrawtransaction, params: "\(txID)", response: { (result, error) in
                if error != nil {
                    print("error getrawtransaction = \(String(describing: error))")
                } else {
                    //print("result = \(String(describing: result))")
                    if let rw = result as? String {
                        print("raw transaction result = \(rw)")
                        
                        
                        DispatchQueue.main.async {
                            self.ssh.execute(command: BTC_COMMAND.decoderawtransaction, params: "\"\(rw)\"", response: { (result, error) in
                                if error != nil {
                                    print("error decoderawtransaction = \(String(describing: error))")
                                } else {
                                    //print("result = \(String(describing: result))")
                                    
                                    if let decodedTx = result as? NSDictionary {
                                        DispatchQueue.main.async {
                                            print("decodedTx Prevoutput = \(decodedTx)")
                                            
                                            
                                            if let vout = decodedTx["vout"] as? NSArray {
                                                
                                                print("vout = \(vout)")
                                                
                                                var total = 0.0
                                                
                                                for i in vout {
                                                    
                                                    if let dict = i as? NSDictionary {
                                                        
                                                        if let n = dict["n"] as? Int {
                                                         
                                                            if n == prevvout {
                                                             
                                                                if let value = dict["value"] as? Double {
                                                                    
                                                                    print("value = \(value)")
                                                                    total = value + total
                                                                    self.totalInputs = total
                                                                    
                                                                    
                                                                }
                                                                
                                                            }
                                                            
                                                        }
                                                        
                                                        
                                                        
                                                        /*if let voutN = dict["n"] as? Int {
                                                            
                                                            if voutN == self.utxoVout {
                                                                // ding ding sing this is the previnput amount to get the original mining fee by subtracting this amount to the amount received
                                                                //print("ding ding = \(i)")
                                                                
                                                                if let value = dict["value"] as? Double {
                                                                    
                                                                    print("value = \(value)")
                                                                    total = value + total
                                                                    self.prevInputAmountTotal = total
                                                                    
                                                                    let amountDouble = Double(self.amount)!
                                                                    self.newFee = self.prevInputAmountTotal - amountDouble
                                                                    print("self.prevInputAmountTotal = \(self.prevInputAmountTotal), amount = \(self.amount)")
                                                                    self.getChangeAddressForCPFP()
                                                                }
                                                            }
                                                        }*/
                                                        
                                                        /*if let scriptPubKey = dict["scriptPubKey"] as? NSDictionary {
                                                            
                                                            if let addresses = scriptPubKey["addresses"] as? NSArray {
                                                                
                                                                for i in addresses {
                                                                    
                                                                    if let address = i as? String {
                                                                        
                                                                        if address == self.address {
                                                                            
                                                                            if let value = dict["value"] as? Double {
                                                                                
                                                                                print("value = \(value)")
                                                                                total = value + total
                                                                                self.prevInputAmountTotal = total
                                                                                
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                
                                                                let amountDouble = Double(self.amount)!
                                                                self.newFee = self.prevInputAmountTotal - amountDouble
                                                                print("self.prevInputAmountTotal = \(self.prevInputAmountTotal), amount = \(self.amount)")
                                                                self.getChangeAddressForCPFP()
                                                                
                                                            }
                                                        }*/
                                                    }
                                                }
                                                
                                                let amountDouble = Double(self.amount)!
                                                self.newFee = self.totalInputs - self.totalOutputs//amountDouble
                                                self.newFee = round(100000000*self.newFee)/100000000
                                                let newamount = amountDouble - (self.newFee * 2)
                                                self.amount = String(newamount)
                                                print("new amount = \(self.amount)")
                                                print("totalInputs = \(self.totalInputs) - totalOutputs = \(self.totalOutputs)")
                                                self.getChangeAddressForCPFP()
                                            }
                                        }
                                    }
                                }
                            })
                        }
                    }
                }
            })
        }
    }*/
    
    /*func getChangeAddressForCPFP() {
        
        DispatchQueue.main.async {
            self.ssh.executeStringResponse(command: BTC_COMMAND.getrawchangeaddress, params: "", response: { (result, error) in
                if error != nil {
                    print("error getrawchangeaddress = \(String(describing: error))")
                } else {
                    //print("result = \(String(describing: result))")
                    if let _ = result as? String {
                        
                        self.changeAddress = result!
                        /*print("amount = \(self.amount)")
                        var amountDouble = Double(self.amount)!
                        print("amountDouble = \(amountDouble)")
                        print("newfee = \(self.newFee)")
                        amountDouble = amountDouble - self.newFee
                        print("amountDouble = \(amountDouble)")
                        self.amount = String(amountDouble)
                        print("amount = \(self.amount)")
                        let array = self.amount.split(separator: ".")
                        if array[1].count > 8 {
                            
                            let roundedamount = round(100000000*self.changeAmount)/100000000
                            self.amount = String(roundedamount)
                            //print("sumofutxo = \(sumOfUtxo), txfee = \(txFee)")
                        }
                        print("amount = \(self.amount)")
                        self.changeAmount = self.changeAmount - (self.newFee * 2)
                        if self.changeAmount < 0 {
                            self.changeAmount = -1 * self.changeAmount
                            
                            let array = String(self.changeAmount).split(separator: ".")
                            if array[1].count > 8 {
                                
                                self.changeAmount = round(100000000*self.changeAmount)/100000000
                                //print("sumofutxo = \(sumOfUtxo), txfee = \(txFee)")
                            }
                            //self.amount = "\(sumOfUtxo - txFee - 0.00050000)"
                            
                        }*/
                        self.createRawTransactionCPFP()
                    }
                }
            })
        }
    }*/
    
    /*func createRawTransactionCPFP() {
        
        DispatchQueue.main.async {
            self.ssh.executeStringResponse(command: BTC_COMMAND.createrawtransaction, params: "\'\(self.inputs)\' \'{\"\(self.address)\":\(self.amount), \"\(self.changeAddress)\": \(self.changeAmount)}\'", response: { (result, error) in
                if error != nil {
                    print("error createrawtransaction = \(String(describing: error))")
                } else {
                    print("result = \(String(describing: result))")
                    if let rawTx = result as? String {
                        
                        self.rawTxUnsigned = rawTx
                        self.signRawTransactionCPFP()
                        
                    }
                    
                }
            })
        }
    }*/
    
    /*func signRawTransactionCPFP() {
        
        DispatchQueue.main.async {
            self.ssh.execute(command: BTC_COMMAND.signrawtransaction, params: "\'\(self.rawTxUnsigned)\'", response: { (result, error) in
                if error != nil {
                    print("error signrawtransaction = \(String(describing: error))")
                } else {
                    print("result = \(String(describing: result))")
                    
                    if let signedTransaction = result as? NSDictionary {
                        
                        self.rawTxSigned = signedTransaction["hex"] as! String
                        self.pushRawTx()
                    }
                }
            })
        }
    }*/
    
    /*func pushRawTx(ssh: SSHService) {
        
        let queue = DispatchQueue(label: "com.FullyNoded.getInitialNodeConnection")
        queue.async {//DispatchQueue.main.async {
            ssh.executeStringResponse(command: BTC_COMMAND.sendrawtransaction, params: "\"\(self.rawTxSigned)\"", response: { (result, error) in
                if error != nil {
                    print("error sendrawtransaction = \(String(describing: error))")
                } else {
                    print("result = \(String(describing: result))")
                    
                    if let txID = result as? String {
                        
                        DispatchQueue.main.async {
                            
                            self.refresh()
                            displayAlert(viewController: self, title: "Success", message: "Fee doubled and transaction resent.")
                            
                            
                            /*UIPasteboard.general.string = txID
                            
                            let alert = UIAlertController(title: NSLocalizedString("Success", comment: ""), message: "ID copied to clipboard", preferredStyle: UIAlertControllerStyle.actionSheet)
                            
                            alert.addAction(UIAlertAction(title: NSLocalizedString("Done", comment: ""), style: .cancel, handler: { (action) in
                                self.dismiss(animated: true, completion: nil)
                            }))
                            
                            alert.popoverPresentationController?.sourceView = self.view
                            
                            self.present(alert, animated: true) {
                            }*/
                        }
                        
                    } else {
                        displayAlert(viewController: self, title: "Error", message: "Unable to parse Transaction ID.")
                    }
                }
            })
        }
        
    }*/
    
    /*func parseDecodedTx(decodedTx: NSDictionary) {
        
        print("parseDecodedTx")
        
        if let vin = decodedTx["vin"] as? NSArray {
            
            for i in vin {
                
                print("i = \(i)")
             
                if let dict = i as? NSDictionary {
                 
                    if let inputTxID = dict["txid"] as? String {
                        
                        print("preInputID = \(inputTxID)")
                        //self.getPrevInputValueForCPFP(txID: inputTxID, prevvout)
                    }
                    
                }
                
            }
            
        }
        
        if let vout = decodedTx["vout"] as? NSArray {
            
            print("vout = \(vout)")
            
            for i in vout {
                
                if let dict = i as? NSDictionary {
                    
                    if let value = dict["value"] as? Double {
                        
                        print("value = \(value)")
                        self.total = value + self.total
                        
                    }
                    
                    if let scriptPubKey = dict["scriptPubKey"] as? NSDictionary {
                        
                        if let addresses = scriptPubKey["addresses"] as? NSArray {
                            
                            for i in addresses {
                                
                                if let address = i as? String {
                                    
                                    if address == self.recipientAddress {
                                        
                                        if let voutN = dict["n"] as? Int {
                                            
                                            print("voutN = \(voutN)")
                                            self.utxoVout = voutN
                                            
                                            if let txID = decodedTx["txid"] as? String {
                                                
                                                print("txID = \(txID)")
                                                self.utxoTxId = txID
                                                let input = "{\"txid\":\"\(self.utxoTxId)\",\"vout\": \(self.utxoVout),\"sequence\": 1}"
                                                self.inputArray.append(input)
                                                self.inputs = self.inputArray.description
                                                self.inputs = self.inputs.replacingOccurrences(of: "[\"", with: "[")
                                                self.inputs = self.inputs.replacingOccurrences(of: "\"]", with: "]")
                                                self.inputs = self.inputs.replacingOccurrences(of: "\"{", with: "{")
                                                self.inputs = self.inputs.replacingOccurrences(of: "}\"", with: "}")
                                                self.inputs = self.inputs.replacingOccurrences(of: "\\", with: "")
                                                
                                                //get old fee and double it
                                                //get new change address
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }*/
    
    /*func parseDecodedTxCPFP(decodedTx: NSDictionary) {
        
        print("parseDecodedTxCPFP")
        
        
        
        if let vout = decodedTx["vout"] as? NSArray {
            
            print("vout = \(vout)")
            
            self.totalOutputs = 0
            
            for i in vout {
                
                if let dict = i as? NSDictionary {
                    
                    if let value = dict["value"] as? Double {
                        
                        print("value = \(value)")
                        self.totalOutputs = self.totalOutputs + value
                        
                    }
                    
                    if let scriptPubKey = dict["scriptPubKey"] as? NSDictionary {
                        
                        if let addresses = scriptPubKey["addresses"] as? NSArray {
                            
                            for i in addresses {
                                
                                if let address = i as? String {
                                    
                                    if address == self.recipientAddress {
                                        
                                        if let voutN = dict["n"] as? Int {
                                            
                                            print("voutN = \(voutN)")
                                            self.utxoVout = voutN
                                            
                                            if let txID = decodedTx["hash"] as? String {
                                                
                                                print("txID = \(txID)")
                                                self.utxoTxId = txID
                                                let input = "{\"txid\":\"\(self.utxoTxId)\",\"vout\": \(self.utxoVout),\"sequence\": 1}"
                                                self.inputArray.append(input)
                                                self.inputs = self.inputArray.description
                                                self.inputs = self.inputs.replacingOccurrences(of: "[\"", with: "[")
                                                self.inputs = self.inputs.replacingOccurrences(of: "\"]", with: "]")
                                                self.inputs = self.inputs.replacingOccurrences(of: "\"{", with: "{")
                                                self.inputs = self.inputs.replacingOccurrences(of: "}\"", with: "}")
                                                self.inputs = self.inputs.replacingOccurrences(of: "\\", with: "")
                                                
                                                print("inputarray = \(self.inputArray)")
                                                
                                                
                                                //get old fee and double it
                                                //get new change address
                                                
                                                if let vin = decodedTx["vin"] as? NSArray {
                                                    
                                                    for i in vin {
                                                        
                                                        if let dict = i as? NSDictionary {
                                                            
                                                            print("input = \(dict)")
                                                            
                                                            if let inputTxID = dict["txid"] as? String {
                                                                
                                                                if let inputVout = dict["vout"] as? Int {
                                                                    
                                                                    self.getPrevInputValueForCPFP(txID: inputTxID, prevvout: inputVout)
                                                                    
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                                /*if let vin = decodedTx["vin"] as? NSArray {
                                                    
                                                    for i in vin {
                                                        
                                                        if let dict = i as? NSDictionary {
                                                            
                                                            if let inputTxID = dict["txid"] as? String {
                                                                
                                                                print("preInputID = \(inputTxID)")
                                                                self.getPrevInputValueForCPFP(txID: inputTxID)
                                                            }
                                                        }
                                                    }
                                                }*/
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }*/
    
    func showConnectionError() {
     
        DispatchQueue.main.async {
            
            let alert = UIAlertController(title: "Error", message: "We had an issue connecting to that node via your RPC credentials. If you are using a SSH password to connect to your node please tap \"Try SSH\" below.\n\nIf you are using RPC credentials make sure you enter port 8332 for mainnet or 18332 for testnet when filling out your credentials. You can renew your credentials by tapping the settings button.", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Try SSH", comment: ""), style: .default, handler: { (action) in
                
                if let password = UserDefaults.standard.string(forKey: "NodePassword") {
                    
                    DispatchQueue.main.async {
                        
                        UserDefaults.standard.set(password, forKey: "sshPassword")
                        self.isUsingSSH = true
                        UserDefaults.standard.synchronize()
                        self.activityIndicator.startAnimating()
                        self.refresh()
                        
                    }
                    
                } else {
                    
                    displayAlert(viewController: self, title: "Error", message: "No password was saved, please go to settings to reenter a password")
                    
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Renew RPC Credentials", comment: ""), style: .default, handler: { (action) in
                
                self.renewCredentials()
                
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action) in
                
                
            }))
            
            alert.popoverPresentationController?.sourceView = self.view
            
            self.present(alert, animated: true) {
            }
            
        }
        
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return UIInterfaceOrientationMask.portrait }

}

extension Double {
    
    func withCommas() -> String {
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        return numberFormatter.string(from: NSNumber(value:self))!
    }
    
}
