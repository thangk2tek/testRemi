const { assert } = require("chai");
const { default: Web3 } = require("web3");

const ERC721NFTMarket = artifacts.require('ERC721NFTMarket');
const NFT = artifacts.require('NFT');
require('chai')
.use(require('chai-as-promised'))
.should()

contract('ERC721NFTMarket', (accounts) => {
    it('test get info', async() => {
        const contract = await ERC721NFTMarket.deployed()
        console.log('address' , contract.address)
        const addressReceiveFee = await contract.serviceFeeReceiver()
        console.log('address receive fee' , addressReceiveFee);
        const serviceFee = await contract.serviceFee()
        console.log('serviceFee ', serviceFee);
    })

    it('test put on sale , cancle sale, buy on sale', async()=>{
        const nft = await NFT.deployed();
        const market = await ERC721NFTMarket.deployed()

        await nft.setPriceBNBPerNFT(web3.utils.toWei('1', 'Ether'));
        const addressNFT = nft.address;
        const price = await nft.priceBNBPerNFT();

        //put on sale
        await nft.mint(accounts[1],{from: accounts[1] , value: price})
        const priceSale = web3.utils.toWei('1', 'Ether');
        await market.putOnSale(addressNFT,0, priceSale, {from:accounts[1]}).should.be.rejected;

        await nft.setApprovalForAll(market.address,true, {from: accounts[1]})
        await market.putOnSale(addressNFT,0, priceSale, {from:accounts[1]})

        //cancle sale

        await market.cancelSale(addressNFT , 0 , {from: accounts[0]}).should.be.rejected
        await market.cancelSale(addressNFT , 0 , {from: accounts[1]})

        //buy on sale
        await market.putOnSale(addressNFT,0, priceSale, {from:accounts[1]})
        await market.buyOnSale(addressNFT,0,{from: accounts[1], value:priceSale}).should.be.rejected
        await market.buyOnSale(addressNFT,0,{from: accounts[2], value:priceSale})
    })
})