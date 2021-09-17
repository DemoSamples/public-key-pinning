//
//  main.swift
//  GetPublicKey
//
//  Created by Rajan Twanabashu on 14/09/2021.
//

import Foundation

print("---------------- iOS -----------------")
if CommandLine.arguments.count > 1 {
    let host = CommandLine.arguments[1]
    PublicKeyPinning().validatePublicKey(forURL:"https://" + host)
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 2))
}else{
    print("No host name provided")
}
print("---------------------------------\n")
