/*
 # O'Reilly - Accelerated Hands-on Smart Contract Development with Hyperledger Fabric V2
 # farma ledger supply chain network
 # Author: Brian Wu
 # EquipmentService -makeEquipment:
 */

'use strict';

// Bring key classes into scope, most importantly Fabric SDK network class
const fs = require('fs');
const yaml = require('js-yaml');
const { Wallets, Gateway } = require('fabric-network');
const PharmaLedgerContract = require('../../contract/lib/pharmaledgercontract.js');
class EquipmentService {
  /**
  * 1. Select an identity from a wallet
  * 2. Connect to network gateway
  * 3. Access farma ledger supply chain network
  * 4. Construct request to makeEquipment
  * 5. Submit invoke makeEquipment transaction
  * 6. Process response
  **/
   async makeEquipment(userName, manufacturer, equipmentNumber, equipmentName, ownerName) {
    // A wallet stores a collection of identities for use
    const wallet = await Wallets.newFileSystemWallet('../identity/user/'+userName+'/wallet');
    // A gateway defines the peers used to access Fabric networks
    const gateway = new Gateway();
    try {
      // Load connection profile; will be used to locate a gateway
      let connectionProfile = yaml.safeLoad(fs.readFileSync('../../../organizations/peerOrganizations/org1.example.com/connection-org1.json', 'utf8'));
      // Set connection options; identity and wallet
      let connectionOptions = {
        identity: userName,
        wallet: wallet,
        discovery: { enabled:true, asLocalhost: true }
      };
      // Connect to gateway using application specified parameters
      console.log('Connect to Fabric gateway.');
      await gateway.connect(connectionProfile, connectionOptions);
      // Access farma ledger supply chain network
      console.log('Use network channel: plnchannel.');
      const network = await gateway.getNetwork('plnchannel');
      // Get addressability to farma ledger supply chain network contract
      console.log('Use org.pln.PharmaLedgerContract smart contract.');
      const contract = await network.getContract('pharmaLedgerContract', 'org.pln.PharmaLedgerContract');
      // makeEquipment
      console.log('Submit pharmaledger makeEquipment transaction.');
      const response = await contract.submitTransaction('makeEquipment', manufacturer, equipmentNumber, equipmentName, ownerName);
      console.log('MakeEquipment Transaction complete.');
      return response;
    } catch (error) {
      console.log(`Error processing transaction. ${error}`);
      console.log(error.stack);
      throw ({ status: 500,  message: `Error adding to wallet. ${error}` });
    } finally {
      // Disconnect from the gateway
      console.log('Disconnect from Fabric gateway.')
      gateway.disconnect();
    }
  }
}
// Main program function
module.exports = EquipmentService;
