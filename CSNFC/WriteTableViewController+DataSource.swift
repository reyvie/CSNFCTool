/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Message table view controller
*/

import UIKit
import CoreNFC
import os
extension WriteTableViewController {
    

    // MARK: - Table View Functions
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return detectedMessages.count
        return dummyData.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

//        let message = detectedMessages[indexPath.row]
//        let unit = message.records.count == 1 ? " Payload" : " Payloads"
//        cell.textLabel?.text = message.records.count.description + unit
//        print(message)
//
//        print(message)
//        return cell
//
        
        let message = dummyData[indexPath.row]
        cell.textLabel?.text = message
        return cell
    }
    func createURLPayload() -> NFCNDEFPayload? {
        print(selected)
        let urlComponent = URLComponents(string: "cstap://opentile?guid=\(selected)" )
        os_log("url: %@", (urlComponent?.string)!)
        return NFCNDEFPayload.wellKnownTypeURIPayload(url: (urlComponent?.url)!)
    }
    
    


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selected = dummyData[indexPath.row]
        print(selected)
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your iPhone near an NDEF tag to write the message."
        session?.begin()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        guard let indexPath = tableView.indexPathForSelectedRow,
//            let payloadsTableViewController = segue.destination as? PayloadsTableViewController else {
//            return
//        }
        //payloadsTableViewController.message = detectedMessages[indexPath.row]
    }

}
