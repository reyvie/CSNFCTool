//
//  ScanTagViewController.swift
//  NFCTagReader
//
//  Created by Reyvie Bautista on 12/2/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit
import CoreNFC
import Alamofire

extension NFCTypeNameFormat: CustomStringConvertible {
    public var description: String {
        switch self {
        case .nfcWellKnown: return "NFC Well Known type"
        case .media: return "Media type"
        case .absoluteURI: return "Absolute URI type"
        case .nfcExternal: return "NFC External type"
        case .unknown: return "Unknown type"
        case .unchanged: return "Unchanged type"
        case .empty: return "Empty payload"
        @unknown default: return "Invalid data"
        }
    }
}

class ScanTagViewController: UIViewController, NFCNDEFReaderSessionDelegate {
    
    @IBOutlet weak var detailsLabel: UILabel!
    //MARK: - PROPERTIES
    var detectedMessages = [NFCNDEFMessage]()
    var session: NFCNDEFReaderSession?
    var status: String = ""
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        DispatchQueue.main.async {
            // Process detected NFCNDEFMessage objects.
            self.detectedMessages.removeAll()
            self.detectedMessages.append(contentsOf: messages)
            
            let payload = self.detectedMessages[0].records
            print("detected: \(self.detectedMessages)")
            switch payload[0].typeNameFormat {
            case .nfcWellKnown:
                if let type = String(data: payload[0].type, encoding: .utf8) {
                    if let url = payload[0].wellKnownTypeURIPayload() {
                        //print()
                        self.detailsLabel.text = "\(payload[0].typeNameFormat.description): \(type), \(url.absoluteString)"
                        
                    } else {
                        self.detailsLabel.text = "\(payload[0].typeNameFormat.description): \(type), \(payload[0].wellKnownTypeTextPayload().0!)"
                    }
                }
            case .absoluteURI:
                if let text = String(data: payload[0].payload, encoding: .utf8) {
                    self.detailsLabel.text = "\(text)"
                }
            case .media:
                if let type = String(data: payload[0].type, encoding: .utf8) {
                    self.detailsLabel.text = "\(payload[0].typeNameFormat.description): " + type
                }
            case .nfcExternal, .empty, .unknown, .unchanged:
                fallthrough
            @unknown default:
                self.detailsLabel.text = payload[0].typeNameFormat.description
            }
            //self.tableView.reloadData()
        }
    }
    
    /// - Tag: processingNDEFTag
       func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
           if tags.count > 1 {
               // Restart polling in 500ms
               let retryInterval = DispatchTimeInterval.milliseconds(500)
               session.alertMessage = "More than 1 tag is detected, please remove all tags and try again."
               DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                   session.restartPolling()
               })
               return
           }
           
           // Connect to the found tag and perform NDEF message reading
           let tag = tags.first!
           session.connect(to: tag, completionHandler: { (error: Error?) in
               if nil != error {
                   session.alertMessage = "Unable to connect to tag."
                   session.invalidate()
                   return
               }
               
               tag.queryNDEFStatus(completionHandler: { (ndefStatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                   if .notSupported == ndefStatus {
                       session.alertMessage = "Tag is not NDEF compliant"
                       session.invalidate()
                       return
                   } else if nil != error {
                       session.alertMessage = "Unable to query NDEF status of tag"
                       session.invalidate()
                       return
                   }
                switch ndefStatus.rawValue {
                case 1:
                    self.status = "Not supported both Read and Write"
                case 2:
                    self.status = "Read and Write"
                case 3:
                    self.status = "Read Only"
                default:
                    self.status = "Not supported"
                }
                   tag.readNDEF(completionHandler: { (message: NFCNDEFMessage?, error: Error?) in
                       var statusMessage: String
                    
                    
                        
                       if nil != error || nil == message {
                           statusMessage = "Fail to read NDEF from tag"
                       } else {
                           statusMessage = "Found 1 NDEF message"
                           DispatchQueue.main.async {
                               // Process detected NFCNDEFMessage objects.
                            self.detectedMessages.removeAll()
                               self.detectedMessages.append(message!)
                            print(self.detectedMessages)
                               //self.tableView.reloadData()
                            let payload = self.detectedMessages[0].records
                            print("detected: \(self.detectedMessages)")
                            for data in 0...payload.count-1{
                                switch payload[data].typeNameFormat {
                                case .nfcWellKnown:
                                    if let type = String(data: payload[data].type, encoding: .utf8) {
                                        if let url = payload[data].wellKnownTypeURIPayload() {
                                            
                                            self.detailsLabel.text! += "\(payload[data].typeNameFormat.description): \(type)RI \n\n" +
                                            "Status: \(self.status) \n\n" +
                                            "Tag Size: \(payload[data].payload) \n\n" +
                                            "Maximum Capacity: \(capacity) bytes \n\n" +
                                            "URI Content: \n\(url.absoluteString) \n\n\n\n\n"
                                            
                                        } else {
                                            self.detailsLabel.text! += "\(payload[data].typeNameFormat.description): \(type)ext \n\n" +
                                            "Status: \(self.status) \n\n" +
                                            "Tag Size: \(payload[data].payload) \n\n" +
                                            "Maximum Capacity: \(capacity) bytes \n\n" +
                                            "Text Content: \n\(payload[data].wellKnownTypeTextPayload().0!)\n\n\n\n\n"
                                        }
                                    }
                                case .absoluteURI:
                                    if let text = String(data: payload[0].payload, encoding: .utf8) {
                                        self.detailsLabel.text = "\(text)"
                                    }
                                case .media:
                                    if let type = String(data: payload[0].type, encoding: .utf8) {
                                        self.detailsLabel.text = "\(payload[0].typeNameFormat.description): " + type
                                    }
                                case .nfcExternal, .empty, .unknown, .unchanged:
                                    fallthrough
                                @unknown default:
                                    self.detailsLabel.text = payload[0].typeNameFormat.description
                                }
                            }
                           }
                       }
                       
                       session.alertMessage = statusMessage
                       session.invalidate()
                   })
               })
           })
       }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        //let urlPayload = self.createURLPayload()
       // message = NFCNDEFMessage(records: [urlPayload!])
    }
    
    /// - Tag: endScanning
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
         // Check the invalidation reason from the returned error.
         if let readerError = error as? NFCReaderError {
             // Show an alert when the invalidation reason is not because of a
             // successful read during a single-tag read session, or because the
             // user canceled a multiple-tag read session from the UI or
             // programmatically using the invalidate method call.
             if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead)
                 && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                 let alertController = UIAlertController(
                     title: "Session Invalidated",
                     message: error.localizedDescription,
                     preferredStyle: .alert
                 )
                 alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                 DispatchQueue.main.async {
                     self.present(alertController, animated: true, completion: nil)
                 }
             }
         }

         // To read new tags, a new session instance is required.
         self.session = nil
     }
    //MARK: - ACTIONS
    @IBAction func beginScanning(_ sender: Any) {
        self.detailsLabel.text = ""
        guard NFCNDEFReaderSession.readingAvailable else {
            let alertController = UIAlertController(
                title: "Scanning Not Supported",
                message: "This device doesn't support tag scanning.",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your iPhone near the item to learn more about it."
        session?.begin()
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
