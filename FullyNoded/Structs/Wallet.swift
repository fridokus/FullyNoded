//
//  Wallet.swift
//  BitSense
//
//  Created by Peter on 28/06/20.
//  Copyright © 2020 Fontaine. All rights reserved.
//

import Foundation

public struct Wallet: CustomStringConvertible {
    
    let id:UUID
    let label:String
    let changeDescriptor:String
    let receiveDescriptor:String
    let type:String
    let name:String
    let maxIndex:Int64
    let index:Int64
    let watching:[String]?
    let account:Int16
    let blockheight:Int64
    
    init(dictionary: [String: Any]) {
        id = dictionary["id"] as! UUID
        label = dictionary["label"] as? String ?? "Add label"
        changeDescriptor = dictionary["changeDescriptor"] as! String
        receiveDescriptor = dictionary["receiveDescriptor"] as! String
        type = dictionary["type"] as! String
        name = dictionary["name"] as? String ?? ""
        maxIndex = dictionary["maxIndex"] as? Int64 ?? 0
        index = dictionary["index"] as? Int64 ?? 0
        watching = dictionary["watching"] as? [String]
        account = dictionary["account"] as? Int16 ?? 0
        blockheight = dictionary["blockheight"] as? Int64 ?? 0
    }
    
    public var description: String {
        return ""
    }
}
