#!/bin/bash

# O'Reilly - Accelerated Hands-on Smart Contract Development with Hyperledger Fabric V2
# farma ledger supply chain network
# Author: Brian Wu
# deploy smart contract

CHANNEL_NAME="$1"
CC_SRC_LANGUAGE="$2"
VERSION="$3"
DELAY="$4"
MAX_RETRY="$5"
VERBOSE="$6"
: ${CHANNEL_NAME:="plnchannel"}
: ${CC_SRC_LANGUAGE:="javascript"}
: ${VERSION:="1"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}
CC_SRC_LANGUAGE=`echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:]`
CC_RUNTIME_LANGUAGE=node # chaincode runtime language is node.js
CC_SRC_PATH="organizations/manufacturer/contract/"
CHINCODE_NAME="pharmaLedgerContract"
FABRIC_CFG_PATH=$PWD/../config/

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Deploy smart contract Pharma Ledger Network (PLN) fabric blockchain"
echo

# import utils
. scripts/utils.sh


packageChaincode() {
  ORG=$1
  setGlobalVars $ORG
  starCallFuncWithStepLog "packageChaincode" 1
  set -x
  peer lifecycle chaincode package ${CHINCODE_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CHINCODE_NAME}_${VERSION} >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode packaging on peer0.org${ORG} has failed"
  endCallFuncLogWithMsg "packageChaincode" "Chaincode is packaged on peer0.org${ORG}"
  #echo "===================== Chaincode is packaged on peer0.org${ORG} ===================== "
  echo
}
installChaincodes() {
  CHAINCODE_ORGS=$1
  starCallFuncWithStepLog "installChaincodes" 2
	for org in $(seq 1 $CHAINCODE_ORGS); do
		installChaincode $org
		sleep $DELAY
		echo
	done
	endCallFuncLogWithMsg "installChaincodes" "Chaincode installed"
}
# installChaincode PEER ORG
installChaincode() {
  ORG=$1
  setGlobalVars $ORG
  starCallFuncWithStepLog "installChaincode org$ORG" 2
  set -x
  peer lifecycle chaincode install ${CHINCODE_NAME}.tar.gz >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode installation on peer0.org${ORG} has failed"
  endCallFuncLogWithMsg "installChaincode" "Chaincode is installed on peer0.org${ORG}"
  #echo "===================== Chaincode is installed on peer0.org${ORG} ===================== "
  echo
}

# queryInstalled PEER ORG
queryInstalled() {
  ORG=$1
  setGlobalVars $ORG
  starCallFuncWithStepLog "queryInstalled" 3
  set -x
  peer lifecycle chaincode queryinstalled >&log.txt
  res=$?
  set +x
  cat log.txt
	PACKAGE_ID=$(sed -n "/${CHINCODE_NAME}_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  verifyResult $res "Query installed on peer0.org${ORG} has failed"
  endCallFuncLogWithMsg "queryInstalled" "Query installed successful with PackageID is ${PACKAGE_ID}"
  #echo "===================== Query installed successful on peer0.org${ORG} on channel ===================== "
  echo
}

# approveForMyOrg VERSION PEER ORG
approveForMyOrg() {
  ORG=$1
  setGlobalVars $ORG
  starCallFuncWithStepLog "approveForMyOrg" 4
  set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CHINCODE_NAME} --version ${VERSION}  --package-id ${PACKAGE_ID} --sequence ${VERSION} >&log.txt
  set +x
  cat log.txt
  verifyResult $res "Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  endCallFuncLogWithMsg "approveForMyOrg" "Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME'"
  #echo "===================== Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME' ===================== "
  echo
}

# checkCommitReadiness VERSION PEER ORG
checkOrgsCommitReadiness() {
  CHECK_COMMIT_ORGS=$1
  ORG1_BOOL=$2
  ORG2_BOOL=$3
  ORG3_BOOL=$4
  VERIFY_ORG_MSG1=""
  VERIFY_ORG_MSG2=""
  VERIFY_ORG_MSG3=""
  starCallFuncWithStepLog "checkOrgsCommitReadiness" 5
  for org in $(seq 1 $CHECK_COMMIT_ORGS); do
    if [ $ORG1_BOOL -eq 1 ]; then
      $VERIFY_ORG_MSG1 = "\"Org1MSP\": true"
    else
      $VERIFY_ORG_MSG1 = "\"Org1MSP\": false"
    fi
    if [ $ORG2_BOOL -eq 1 ]; then
      $VERIFY_ORG_MSG2 = "\"Org2MSP\": true"
    else
      $VERIFY_ORG_MSG2 = "\"Org2MSP\": false"
    fi
    if [ $ORG3_BOOL -eq 1 ]; then
      $VERIFY_ORG_MSG3 = "\"Org3MSP\": true"
    else
      $VERIFY_ORG_MSG3 = "\"Org3MSP\": false"
    fi
    VERIFY_MSG="$VERIFY_ORG_MSG1 $VERIFY_ORG_MSG2 $VERIFY_ORG_MSG3"
    checkCommitReadiness $org $VERIFY_MSG
    sleep $DELAY
    echo
  done
  endCallFuncLogWithMsg "checkOrgsCommitReadiness" "Chaincode installed"
}

checkCommitReadiness() {
  ORG=$1
  shift 1
  setGlobalVars $ORG
  starCallFuncWithStepLog "checkCommitReadiness org$ORG" 5
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to check the commit readiness of the chaincode definition on peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name ${CHINCODE_NAME} --version ${VERSION} --sequence ${VERSION} --output json >&log.txt
    res=$?
    set +x
    let rc=0
    for var in "$@"
    do
      grep "$var" log.txt &>/dev/null || let rc=1
    done
		COUNTER=$(expr $COUNTER + 1)
	done
  cat log.txt
  if test $rc -eq 0; then
    endCallFuncLogWithMsg "checkCommitReadiness" "Checking the commit readiness of the chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME'"
    #echo "===================== Checking the commit readiness of the chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME' ===================== "
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Check commit readiness result on peer0.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
commitChaincodeDefinition() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "
  starCallFuncWithStepLog "commitChaincodeDefinition" 6
  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CHINCODE_NAME} $PEER_CONN_PARMS --version ${VERSION} --sequence ${VERSION} >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode definition commit failed on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  endCallFuncLogWithMsg "commitChaincodeDefinition" "Chaincode definition committed on channel '$CHANNEL_NAME'"

  #echo "===================== Chaincode definition committed on channel '$CHANNEL_NAME' ===================== "
  echo
}
queryAllCommitted() {
  COMMITTED_ORGS=$1
  starCallFuncWithStepLog "queryAllCommitted" 7
	for org in $(seq 1 $COMMITTED_ORGS); do
		queryCommitted $org
		sleep $DELAY
		echo
	done
	endCallFuncLogWithMsg "queryAllCommitted" "Chaincode installed"
}
# queryCommitted ORG
queryCommitted() {
  ORG=$1
  setGlobalVars $ORG
  EXPECTED_RESULT="Version: ${VERSION}, Sequence: ${VERSION}, Endorsement Plugin: escc, Validation Plugin: vscc"
  starCallFuncWithStepLog "queryCommitted org$ORG" 7
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to Query committed status on peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CHINCODE_NAME} >&log.txt
    res=$?
    set +x
		test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: [0-9], Sequence: [0-9], Endorsement Plugin: escc, Validation Plugin: vscc')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
		COUNTER=$(expr $COUNTER + 1)
	done
  echo
  cat log.txt
  verifyResult $res "Query commit failed on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  endCallFuncLogWithMsg "queryCommitted" "Query committed on channel '$CHANNEL_NAME'"
}

## at first we package the chaincode
packageChaincode 1

## Install chaincode on peer0.org1 peer0.org2, and peer0.org3
installChaincodes 3
## query whether the chaincode is installed
queryInstalled 1

## approve Org1
approveForMyOrg 1
## check whether the chaincode definition is ready to be committed, orgs one should be approved
checkOrgsCommitReadiness 3 1 0 0

## approve org2
approveForMyOrg 2
## check whether the chaincode definition is ready to be committed, two orgs should be approved
checkOrgsCommitReadiness 3 1 1 0

## approve org3
approveForMyOrg 3
## check whether the chaincode definition is ready to be committed, all 3 orgs should be approved
checkOrgsCommitReadiness 3 1 1 1

## now that we know for sure called orgs have approved, commit the definition
commitChaincodeDefinition 1 2 3

## query on both orgs to see that the definition committed successfully
queryAllCommitted 3

echo
echo "========= Pharma Ledger Network (PLN) contract successfully deployed on channel $CHANNEL_NAME  =========== "

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
