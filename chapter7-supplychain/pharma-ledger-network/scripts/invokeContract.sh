#!/bin/bash

# O'Reilly - Accelerated Hands-on Smart Contract Development with Hyperledger Fabric V2
# farma ledger supply chain network
# Author: Brian Wu
# invoke smart contract
CHANNEL_NAME=plnchannel
CC_SRC_LANGUAGE=javascript
VERSION=1
DELAY=3
MAX_RETRY=5
VERBOSE=true
CHINCODE_NAME="pharmaLedgerContract"
FABRIC_CFG_PATH=$PWD/../config/

manufacturer=""
equipmentNumber=""
equipmentName=""
ownerName=""

# import utils
. scripts/utils.sh

chaincodeInvokeInit() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "
  starCallFuncWithStepLog "chaincodeInvokeInit" 1
  set -x
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CHINCODE_NAME} $PEER_CONN_PARMS  -c '{"function":"instantiate","Args":[]}' >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  endCallFuncLogWithMsg "chaincodeInvokeInit" "Invoke transaction successful"
  echo
}
invokeMakeEquipment() {
  parsePeerConnectionParameters $@
  echo "invokeMakeEquipment--> manufacturer:$manufacturer, equipmentNumber:$equipmentNumber, equipmentName: $equipmentName,ownerName:$ownerName"
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "
  starCallFuncWithStepLog "invokeMakeEquipment" 2
  set -x
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CHINCODE_NAME} $PEER_CONN_PARMS  -c '{"function":"makeEquipment","Args":["'$manufacturer'","'$equipmentNumber'", "'$equipmentName'", "'$ownerName'"]}' >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  endCallFuncLogWithMsg "invokeMakeEquipment" "Invoke transaction successful"
  echo
}
invokeWholesalerDistribute() {
  parsePeerConnectionParameters $@
  echo "invokeWolesalerDistribute--> equipmentNumber: $equipmentNumber, - ownerName: $ownerName"
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "
  starCallFuncWithStepLog "invokeShipToWholesaler" 3
  set -x
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CHINCODE_NAME} $PEER_CONN_PARMS  -c '{"function":"wholesalerDistribute","Args":[ "'$equipmentNumber'", "'$ownerName'"]}' >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  endCallFuncLogWithMsg "invokeWolesalerDistribute" "Invoke transaction successful"
  echo
}
invokePharmacyReceived() {
  parsePeerConnectionParameters $@
  echo "invokePharmacyReceived--> equipmentNumber: $equipmentNumber, - ownerName: $ownerName"
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "
  starCallFuncWithStepLog "invokePharmacyReceived" 4
  set -x
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CHINCODE_NAME} $PEER_CONN_PARMS  -c '{"function":"pharmacyReceived","Args":["'$equipmentNumber'", "'$ownerName'"]}' >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  endCallFuncLogWithMsg "invokePharmacyReceived" "Invoke transaction successful"
  echo
}
chaincodeQuery() {
  ORG=$1
  QUERY_KEY=$2
  setGlobalVars $ORG
  callStartLog "chaincodeQuery $QUERY_KEY"
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to Query peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer chaincode query -C $CHANNEL_NAME -n ${CHINCODE_NAME} -c '{"function":"queryByKey","Args":["'$QUERY_KEY'"]}' >&log.txt
    res=$?
    set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
  echo
  cat log.txt
  verifyResult $res " Query result on peer0.org${ORG} is INVALID"
  endCallFuncLogWithMsg "chaincodeQuery" "Query successful"
}
chaincodeQueryHistory() {
  ORG=$1
  QUERY_KEY=$2
  setGlobalVars $ORG
  callStartLog "chaincodeQueryHistory"
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to Query peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer chaincode query -C $CHANNEL_NAME -n ${CHINCODE_NAME} -c '{"function":"queryHistoryByKey","Args":["'$QUERY_KEY'"]}' >&log.txt
    res=$?
    set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
  echo
  cat log.txt
  verifyResult $res " Query History result on peer0.org${ORG} is INVALID"
  endCallFuncLogWithMsg "chaincodeQuery" "Query History successful"
}

## Invoke the chaincode
#chaincodeInvokeInit 1 2 3

#sleep 10
#chaincodeQuery 1

#invokeMakeEquipment 1 2 3
#sleep 10
#chaincodeQuery 1

#invokeWolesalerDistribute 1 2 3
#sleep 10
#chaincodeQuery 1

#invokePharmacyReceived 1 2 3
#sleep 10

#chaincodeQuery 1

#chaincodeQueryHistory 1
# Query chaincode on peer0.org1

function printHelp() {
  echo "Usage: "
  echo "  invokeContract.sh <Mode>"
  echo "    <Mode>"
  echo "      - 'init' - invoke chaincodeInvokeInit"
  echo "      - 'query' - query ledger record"
  echo "      - 'queryHistory' - query ledger history records"
  echo "      - 'equipment' - invoke invokeMakeEquipment"
  echo "      - 'wolesaler' - invoke invokeWolesalerDistribute"
  echo "      - 'pharmacy' - invoke invokePharmacyReceived"
  echo
  echo " Examples:"
  echo "  invokeContract.sh init"
  echo "  invokeContract.sh query"
  echo "  invokeContract.sh queryHistory"
  echo "  invokeContract.sh equipment"
  echo "  invokeContract.sh wolesaler"
  echo "  invokeContract.sh pharmacy"
}
## Parse mode
if [[ $# -lt 1 ]] ; then
  printHelp
  exit 0
else
  MODE=$1
  shift
fi


if [ "${MODE}" == "init" ]; then
  chaincodeInvokeInit 1 2 3
elif [ "${MODE}" == "query" ]; then
  if [[ $# -ne 1 ]] ; then
    printHelp
    exit 0
  fi
  chaincodeQuery 1 $1
elif [ "${MODE}" == "queryHistory" ]; then
  if [[ $# -ne 1 ]] ; then
    printHelp
    exit 0
  fi
  chaincodeQueryHistory 1 $1
elif [ "${MODE}" == "equipment" ]; then
  if [[ $# -ne 4 ]] ; then
    printHelp
    exit 0
  fi
  manufacturer=$1
  equipmentNumber=$2
  equipmentName=$3
  ownerName=$4
  invokeMakeEquipment 1 2 3
elif [ "${MODE}" == "wholesaler" ]; then
  if [[ $# -ne 2 ]] ; then
    printHelp
    exit 0
  fi
  equipmentNumber=$1
  ownerName=$2
  invokeWholesalerDistribute 1 2 3
elif [ "${MODE}" == "pharmacy" ]; then
   if [[ $# -ne 2 ]] ; then
    printHelp
    exit 0
  fi
  equipmentNumber=$1
  ownerName=$2
  invokePharmacyReceived 1 2 3
else
  printHelp
  exit 1
fi

exit 0
