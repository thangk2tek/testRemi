// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFT is ERC721Enumerable ,Ownable,Pausable ,ReentrancyGuard{
    using Strings for uint256;

    string public baseURI;
    address public addressBNBReceiver;
    uint256 public priceBNBPerNFT;
    uint256 public maxAmount;

    constructor(string memory _name,string memory _symbol) ERC721(_name, _symbol) {
        maxAmount = 1000;
    }

    function setPause() external onlyOwner {
        _pause();
    }

    function unsetPause() external onlyOwner {
        _unpause();
    }

    function setMaxAmount(uint256 _amount) external onlyOwner {
        maxAmount = _amount;
    }

    function mint(address _to, uint256 _tokenId) payable external whenNotPaused nonReentrant  {
        require(priceBNBPerNFT == msg.value , "amount invalid");
        require(maxAmount > totalSupply() , "sold out");
        (bool bnbReceived, ) = addressBNBReceiver.call{value: msg.value}("");
        require(bnbReceived);
        _mint(_to, _tokenId);
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setAddressBNBReceiver(address _address) external onlyOwner {
        addressBNBReceiver = _address;
    }

    function setPriceBNBPerNFT(uint256 _price) external onlyOwner {
        priceBNBPerNFT = _price;
    }

    function getTokensInfoOfAddress(address user) external view returns (uint256[] memory) {
        uint256 length = balanceOf(user);
        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(user, i);
            values[i] = tokenId;
        }

        return (values);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }
}