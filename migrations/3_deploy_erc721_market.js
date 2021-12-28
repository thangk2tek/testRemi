const ERC721NFTMarket = artifacts.require("ERC721NFTMarket");

module.exports = function (deployer) {
  deployer.deploy(ERC721NFTMarket);
};