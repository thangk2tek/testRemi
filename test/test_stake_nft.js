const { assert } = require("chai");
const { default: Web3 } = require("web3");

const NFT = artifacts.require('NFT');
const StakeNFT = artifacts.require('StakeNFT');
const RewardTest = artifacts.require('RewardTest');

require('chai')
.use(require('chai-as-promised'))
.should()

contract('stake nft', (accounts)=>{
    it('test stake' , async() =>{
        const nft = await NFT.deployed()
        await nft.setPriceBNBPerNFT(web3.utils.toWei('1', 'Ether'));
        const price = await nft.priceBNBPerNFT();
        await nft.mint(accounts[1], {from: accounts[1] , value: price} )
        const stakeNFT = await StakeNFT.deployed()
        const rewardToken = await RewardTest.deployed();
        const add = await stakeNFT.add(nft.address , rewardToken.address , 0, 999999999 , 10000)
        console.log(add);

        await nft.setApprovalForAll(stakeNFT.address,true, {from: accounts[1]})
        const deposit = await stakeNFT.deposit(0,0 , {from: accounts[1]})
        console.log(deposit);

        const getPoint = await stakeNFT.getPoint(0,accounts[1],{from: accounts[1]})
        console.log('point ', getPoint)

        const harvest = await stakeNFT.harvest(0, {from: accounts[1]});
        console.log('harvest ' , harvest);

        const withdraw = await stakeNFT.withdraw(0,0 , {from:accounts[1]})
        console.log(withdraw)
    })
})