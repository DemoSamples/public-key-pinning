//
//  PublicKeyPinning.swift
//  GetPublicKey
//
//  Created by Rajan Twanabashu on 14/09/2021.
//



import Foundation
import Security
import CommonCrypto
import CryptoKit


extension Data {
    var prettyPrintedJSONString: NSString? { /// NSString gives us a nice sanitized debugDescription
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }
        
        return prettyPrintedString
    }
}


enum NetworkError {
    case url
    case request
    case publickey
    
    var desctiption: (Int, String) {
        switch self {
        case .url:
            return (1, "Invalid URL")
        case .request:
            return (2, "Request Error")
            
        case .publickey:
            return (3, "Public key failed to recognized")
        }
    }
}

enum PinningOption {
    case certificate
    case publicKey
}


// CryptoKit.Digest utils
extension Digest {
    var bytes: [UInt8] { Array(makeIterator()) }
    var data: Data { Data(bytes) }
    
    var hexStr: String {
        bytes.map { String(format: "%02X", $0) }.joined()
    }
}


class PublicKeyPinning: NSObject,URLSessionDelegate {
    
    static var publicKey: String = ""
    static var pinningOption: PinningOption = .publicKey
    
    let rsa2048Asn1Header:[UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
    ]
    
    private func sha256(data : Data) -> String {
        var keyWithHeader = Data(rsa2048Asn1Header)
        keyWithHeader.append(data)
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        keyWithHeader.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(keyWithHeader.count), &hash)
        }
        return Data(hash).base64EncodedString()
    }
    
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        //        print(">>>>>> didReceive: ", challenge)
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
      
        let certificateCount =  SecTrustGetCertificateCount(serverTrust)
        for index in 0..<certificateCount {
            guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, index) else {
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
            
            // Server public key
            let serverPublicKey = SecCertificateCopyKey(serverCertificate)
            let serverPublicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey!, nil )!
            let data:Data = serverPublicKeyData as Data
            //print(data.map { String(format: "%02x ", $0) }.joined())
            // Server Hash key
            let serverHashKey = sha256(data: data)
            let serverHashKey1 = SHA256.hash(data: data).data.base64EncodedString()
           // print(SHA256.hash(data: data).data.map { String(format: "%02x ", $0) }.joined())
            
            print("Public Key [\(index)] ", serverHashKey, " alternate: ", serverHashKey1)
           
          
            
            
        }
    }
    

    
    func validatePublicKey(forURL urlString: String) {
        
        print(urlString)
        //Step 1:
        
        
        guard let url = URL(string: urlString) else {
            print(#function, NetworkError.url.desctiption)
            
            
            let error = NSError(domain: "NetworkError", code: NetworkError.url.desctiption.0, userInfo: ["NSLocalizedDescriptionKey" : NetworkError.url.desctiption.1])
            print(error)
            return
        }
        
        //Step 2:
        var request = URLRequest(url: url,timeoutInterval: Double.infinity)
        request.httpMethod = "HEAD"
        
        
        //Step 4
        let session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: request) { data, response, error in
            
            if error != nil {
                print(error!.localizedDescription)
                let error = NSError(domain: "NetworkError", code: NetworkError.publickey.desctiption.0, userInfo: ["NSLocalizedDescriptionKey" : NetworkError.publickey.desctiption.1])
                print(error)
                
            }else{
                print("Seems we ae good to go")
            }
        }
        
        task.resume()
    }
}
