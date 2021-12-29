const { assert } = require("chai");
const { default: Web3 } = require("web3");

const NFT = artifacts.require('NFT');
require('chai')
.use(require('chai-as-promised'))
.should()

contract('NFT' , (accounts)=>{
    it('test get info' , async() => {
        const contract = await NFT.deployed();

        console.log("contract.address", contract.address);

        const name = await contract.name();
        console.log("name", name);
        const symbol = await contract.symbol();
        console.log("symbol", symbol);
        const totalSupply = await contract.totalSupply();
        console.log("totalSupply", BigInt(totalSupply));

        console.log(accounts);

        a0 = accounts[0];
        const b0 = await contract.balanceOf(a0);
        console.log("a0", a0, "b0", BigInt(b0));

    })

    it('test mint nft' , async() =>{
        const contract =await NFT.deployed();
        const to = accounts[2];
        await contract.setPriceBNBPerNFT(web3.utils.toWei('1', 'Ether'));
        const price = await contract.priceBNBPerNFT();
        console.log("price" , BigInt(price))
        const mint = await contract.mint(to,{from: accounts[1] , value: price})
        console.log("mint" , mint);
        const amount = await contract.balanceOf(to);
        console.log("amount of"+ to , BigInt(amount));

        await contract.mint(to, { from: accounts[0], value: web3.utils.toWei('0.5', 'Ether') }).should.be.rejected;
    }) 
})