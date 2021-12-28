const StakeNFT = artifacts.require("StakeNFT");

module.exports = function (deployer) {
  deployer.deploy(StakeNFT);
};