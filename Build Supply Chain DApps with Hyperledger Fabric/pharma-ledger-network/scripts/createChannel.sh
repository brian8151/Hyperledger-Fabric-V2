#!/bin/bash

# O'Reilly - Accelerated Hands-on Smart Contract Development with Hyperledger Fabric V2
# farma ledger supply chain network
# Author: Brian Wu
# create channel

CHANNEL_NAME="$1"
DELAY="$2"
MAX_RETRY="$3"
VERBOSE="$4"
: ${CHANNEL_NAME:="plnchannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}
TOTAL_ORGS=3
# import utils
. scripts/utils.sh

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Creating Pharma Ledger Network (PLN) Channel $CHANNEL_NAME"
echo

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

createChannelTxn() {
	starCallFuncWithStepLog "createChannelTxn" 1
	displayMsg "generate channel configuration transaction"
	set -x
	configtxgen -profile PharmaLedgerChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
	res=$?
	set +x
  verifyResult $res "generate channel $CHANNEL_NAME configuration transaction"
	endCallFuncLogWithMsg "createChannelTxn" "generated channel configuration transaction"
	echo

}

createAncorPeerTxn() {
	starCallFuncWithStepLog "createAncorPeerTxn" 2
	for orgmsp in Org1MSP Org2MSP Org3MSP; do
  displayMsg "Generating anchor peer update transaction for ${orgmsp}"
	set -x
	configtxgen -profile PharmaLedgerChannel -outputAnchorPeersUpdate ./channel-artifacts/${orgmsp}anchors.tx -channelID $CHANNEL_NAME -asOrg ${orgmsp}
	res=$?
	set +x
  verifyResult $res "generate anchor peer update transaction for ${orgmsp} failed"
	echo
	endCallFuncLogWithMsg "createAncorPeerTxn" "generated channel ancor peer transaction"
	done
}

createChannel() {
	setGlobalVars 1
	starCallFuncWithStepLog "createChannel" 3
	# Poll in case the raft leader is not set yet
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		peer channel create -o localhost:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.example.com -f ./channel-artifacts/${CHANNEL_NAME}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
		set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo
  endCallFuncLogWithMsg "createChannel" "Channel '$CHANNEL_NAME' created"
	echo
}
joinMultiPeersToChannel() {
	starCallFuncWithStepLog "joinMultiPeersToChannel" 4
	for org in $(seq 1 $TOTAL_ORGS); do
		ORG=$org
    starCallFuncWithStepLog "joinChannel Org$org" 4
		joinChannel
    endCallFuncLogWithMsg "joinChannel" "peer0.org${org} joined on the channel \"$CHANNEL_NAME\""
		sleep $DELAY
		echo
	done
}
# ORG join channel
joinChannel() {
	setGlobalVars $ORG
	peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block >&log.txt
	res=$?
	cat log.txt
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "peer${PEER}.org${ORG} failed to update Anchor in channel, Retry after $DELAY seconds"
		sleep $DELAY
		joinChannel $ORG
	else
		COUNTER=1
	fi
	verifyResult $res "After $MAX_RETRY attempts, peer0.org${ORG} has failed to join channel '$CHANNEL_NAME' "
}
updateOrgsOnAnchorPeers() {
	starCallFuncWithStepLog "updateOrgsOnAnchorPeers" 5
	for org in $(seq 1 $TOTAL_ORGS); do
    ORG=$org
		starCallFuncWithStepLog "updateAnchorPeers $org" 5
		updateAnchorPeers
    endCallFuncLogWithMsg "updateAnchorPeers" "updated peer0.org${org} on anchorPeers"
		sleep $DELAY
		echo
	done
	endCallFuncLogWithMsg "updateOrgsOnAnchorPeers" "anchorPeers updated"
}
updateAnchorPeers() {
	setGlobalVars $ORG
	peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
	res=$?
	cat log.txt
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "peer${PEER}.org${ORG} failed to update Anchor in channel, Retry after $DELAY seconds"
		sleep $DELAY
		updateAnchorPeersWithRetry $ORG
	else
		COUNTER=1
	fi
	verifyResult $res "After $MAX_RETRY attempts, peer${PEER}.org${ORG} has failed to update anchor in  the Channel"
}
FABRIC_CFG_PATH=${PWD}/configtx

## Create channeltx
echo "### Generating channel create transaction '${CHANNEL_NAME}.tx' ###"
createChannelTxn

## Create anchorpeertx
echo "### Generating anchor peer update transactions ###"
createAncorPeerTxn

FABRIC_CFG_PATH=$PWD/../config/

## Create channel
createChannel

## Join all the peers to the channel
echo "Join Org peers to the channel..."
joinMultiPeersToChannel

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for org..."
updateOrgsOnAnchorPeers

echo
echo "========= Pharma Ledger Network (PLN) Channel $CHANNEL_NAME successfully joined =========== "

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
