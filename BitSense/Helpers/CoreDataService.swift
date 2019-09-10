//
//  CoreDataService.swift
//  BitSense
//
//  Created by Peter on 04/04/19.
//  Copyright © 2019 Fontaine. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class CoreDataService {
    
    func saveCredentialsToCoreData(vc: UIViewController, credentials: [String:Any]) -> Bool {
        print("saveCredentialsToCoreData")
        
        var success = Bool()
        var appDelegate = AppDelegate()
        
        if let appDelegateCheck = UIApplication.shared.delegate as? AppDelegate {
            
            appDelegate = appDelegateCheck
            
        } else {
            
            displayAlert(viewController: vc, isError: true, message: "Unable to convert credentials to coredata.")
            success = false
            
        }
        
        let context = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Nodes", in: context)
        let credential = NSManagedObject(entity: entity!, insertInto: context)
        
        for (key, value) in credentials {
            
            credential.setValue(value, forKey: key)
                
            do {
                    
                try context.save()
                success = true
                print("Saved credential \(key) = \(value)")
                    
            } catch {
                    
                print("Failed saving credential \(key) = \(value)")
                success = false
                    
            }
                
        }
            
        return success
        
    }
    
    func retrieveCredentials() -> [[String:Any]] {
        print("retrieveCredentials")
        
        var credentials = [[String:Any]]()
        var appDelegate = AppDelegate()
        
        DispatchQueue.main.async {
            
            if let appDelegateCheck = UIApplication.shared.delegate as? AppDelegate {
                
                appDelegate = appDelegateCheck
                
            } else {
                
                print("error can't access app delegate")
                
            }
            
        }
        
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Nodes")
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.resultType = .dictionaryResultType
        
        
        do {
            
            if let results = try context.fetch(fetchRequest) as? [[String:Any]] {
                
                if results.count > 0 {
                    
                    for credential in results {
                        
                        credentials.append(credential)
                        
                    }
                    
                }
                
            }
            
        } catch {
            
            print("Failed")
            
        }
        
        return credentials
        
    }
    
    func updateNode(viewController: UIViewController, id: String, newValue: Any, keyToEdit: String) -> Bool {
        
        var boolToReturn = Bool()
        var appDelegate = AppDelegate()
        
        DispatchQueue.main.async {
            
            if let appDelegateCheck = UIApplication.shared.delegate as? AppDelegate {
                
                appDelegate = appDelegateCheck
                
            } else {
                
                boolToReturn = false
                displayAlert(viewController: viewController, isError: true, message: "Something strange has happened and we do not have access to app delegate, please try again.")
                
            }
            
        }
            
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Nodes")
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                
                let results = try context.fetch(fetchRequest) as [NSManagedObject]
                
                if results.count > 0 {
                    
                    for data in results {
                        
                        if id == data.value(forKey: "id") as? String {
                            
                            data.setValue(newValue, forKey: keyToEdit)
                            
                            do {
                                
                                try context.save()
                                boolToReturn = true
                                print("updated successfully")
                                
                            } catch {
                                
                                print("error editing")
                                boolToReturn = false
                                
                            }
                            
                        }
                        
                    }
                    
                } else {
                    
                    print("no results")
                    boolToReturn = false
                    
                }
                
            } catch {
                
                print("Failed")
                boolToReturn = false
                
            }
            
        return boolToReturn
        
    }
    
    func deleteNode(viewController: UIViewController, id: String) -> Bool {
        
        var boolToReturn = Bool()
        var appDelegate = AppDelegate()
        
        DispatchQueue.main.async {
            
            if let appDelegateCheck = UIApplication.shared.delegate as? AppDelegate {
                
                appDelegate = appDelegateCheck
                
            } else {
                
                boolToReturn = false
                displayAlert(viewController: viewController, isError: true, message: "Something strange has happened and we do not have access to app delegate, please try again.")
                
            }
            
        }
        
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Nodes")
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            
            let results = try context.fetch(fetchRequest) as [NSManagedObject]
            
            if results.count > 0 {
                
                for (index, data) in results.enumerated() {
                    
                    if id == data.value(forKey: "id") as? String {
                        
                        context.delete(results[index] as NSManagedObject)
                        
                        do {
                            
                            try context.save()
                            print("deleted succesfully")
                            boolToReturn = true
                            
                        } catch {
                            
                            print("error deleting")
                            print("deleted succesfully")
                            boolToReturn = false
     
                        }
                        
                    }
                    
                }
                
            } else {
                
                print("no results")
                boolToReturn = false
                
            }
            
        } catch {
            
            print("Failed")
            boolToReturn = false
            
        }
        
        return boolToReturn
        
    }
    
    func deleteAllNodes(vc: UIViewController) -> Bool {
        
        var boolToReturn = Bool()
        var appDelegate = AppDelegate()
        
        DispatchQueue.main.async {
            
            if let appDelegateCheck = UIApplication.shared.delegate as? AppDelegate {
                
                appDelegate = appDelegateCheck
                
            } else {
                
                boolToReturn = false
                displayAlert(viewController: vc, isError: true, message: "Something strange has happened and we do not have access to app delegate, please try again.")
                
            }
            
        }
        
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Nodes")
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            
            let results = try context.fetch(fetchRequest) as [NSManagedObject]
            
            if results.count > 0 {
                
                for result in results {
                    
                    context.delete(result as NSManagedObject)
                        
                    do {
                            
                        try context.save()
                        print("deleted succesfully")
                        boolToReturn = true
                            
                    } catch {
                            
                        print("error deleting")
                        print("deleted succesfully")
                        boolToReturn = false
                            
                    }
                    
                }
                
            } else {
                
                print("no results")
                boolToReturn = false
                
            }
            
        } catch {
            
            print("Failed")
            boolToReturn = false
            
        }
        
        return boolToReturn
        
    }
    
    func saveHDWalletToCoreData(vc: UIViewController, walletInfo: [String:Any]) -> Bool {
        print("saveHDWalletToCoreData")
        
        var success = Bool()
        
        DispatchQueue.main.async {
            
            var appDelegate = AppDelegate()
            
            if let appDelegateCheck = UIApplication.shared.delegate as? AppDelegate {
                
                appDelegate = appDelegateCheck
                
            } else {
                
                displayAlert(viewController: vc, isError: true, message: "Unable to convert credentials to coredata.")
                success = false
                
            }
            
            let context = appDelegate.persistentContainer.viewContext
            let entity = NSEntityDescription.entity(forEntityName: "HDWallets", in: context)
            let hdWallet = NSManagedObject(entity: entity!, insertInto: context)
            
            for (key, value) in walletInfo {
                
                hdWallet.setValue(value, forKey: key)
                
                do {
                    
                    try context.save()
                    success = true
                    print("Saved credential \(key) = \(value)")
                    
                } catch {
                    
                    print("Failed saving credential \(key) = \(value)")
                    success = false
                    
                }
                
            }
            
        }
        
        return success
        
    }
    
    func getHDWallets() -> [[String:Any]] {
        print("getHDWallets")
        
        var hdWallets = [[String:Any]]()
        var appDelegate = AppDelegate()
        
        DispatchQueue.main.async {
            
            if let appDelegateCheck = UIApplication.shared.delegate as? AppDelegate {
                
                appDelegate = appDelegateCheck
                
            } else {
                
                print("error can't access app delegate")
                
            }
            
        }
        
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "HDWallets")
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.resultType = .dictionaryResultType
        
        
        do {
            
            if let results = try context.fetch(fetchRequest) as? [[String:Any]] {
                
                if results.count > 0 {
                    
                    for hdWallet in results {
                        
                        hdWallets.append(hdWallet)
                        
                    }
                    
                }
                
            }
            
        } catch {
            
            print("Failed getting HD wallets")
            
        }
        
        return hdWallets
        
    }
    
    func deleteAllHDWallets(vc: UIViewController) -> Bool {
        
        var boolToReturn = Bool()
        var appDelegate = AppDelegate()
        
        DispatchQueue.main.async {
            
            if let appDelegateCheck = UIApplication.shared.delegate as? AppDelegate {
                
                appDelegate = appDelegateCheck
                
            } else {
                
                boolToReturn = false
                
                displayAlert(viewController: vc, isError: true, message: "Something strange has happened and we do not have access to app delegate, please try again.")
                
            }
            
        }
        
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "HDWallets")
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            
            let results = try context.fetch(fetchRequest) as [NSManagedObject]
            
            if results.count > 0 {
                
                for result in results {
                    
                    context.delete(result as NSManagedObject)
                    
                    do {
                        
                        try context.save()
                        print("deleted succesfully")
                        boolToReturn = true
                        
                    } catch {
                        
                        print("error deleting")
                        print("deleted succesfully")
                        boolToReturn = false
                        
                    }
                    
                }
                
            } else {
                
                print("no results")
                boolToReturn = false
                
            }
            
        } catch {
            
            print("Failed")
            boolToReturn = false
            
        }
        
        return boolToReturn
        
    }
    
    func updateWallet(viewController: UIViewController, id: String, newValue: Any, keyToEdit: String) -> Bool {
        
        var boolToReturn = Bool()
        var appDelegate = AppDelegate()
        
        DispatchQueue.main.async {
            
            if let appDelegateCheck = UIApplication.shared.delegate as? AppDelegate {
                
                appDelegate = appDelegateCheck
                
            } else {
                
                boolToReturn = false
                displayAlert(viewController: viewController, isError: true, message: "Something strange has happened and we do not have access to app delegate, please try again.")
                
            }
            
        }
        
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "HDWallets")
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            
            let results = try context.fetch(fetchRequest) as [NSManagedObject]
            
            if results.count > 0 {
                
                for data in results {
                    
                    if id == data.value(forKey: "id") as? String {
                        
                        data.setValue(newValue, forKey: keyToEdit)
                        
                        do {
                            
                            try context.save()
                            boolToReturn = true
                            print("updated successfully")
                            
                        } catch {
                            
                            print("error editing")
                            boolToReturn = false
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                print("no results")
                boolToReturn = false
                
            }
            
        } catch {
            
            print("Failed")
            boolToReturn = false
            
        }
        
        return boolToReturn
        
    }
    
}
