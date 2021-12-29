#########
# Testnet
#########

truffle compile
truffle compile --all && truffle migrate --network testnet --compile-none
#truffle compile --all

# Verify contracts
#truffle run verify --network testnet Migrations
truffle run verify --network testnet

#contract nft : 
#contract stake nft: 
#contract erc721market:  