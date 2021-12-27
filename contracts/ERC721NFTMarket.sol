// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ERC721NFTMarket is ERC721Holder, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    uint256 public serviceFee;
    uint256 public constant FEE_RATIO = 10_000;
    address public serviceFeeReceiver;
    mapping(address => mapping(uint256 => Ask)) public nftsOnSale;  //addressNFT => (nftId => ask)
    mapping(address => mapping(address => EnumerableSet.UintSet)) private _tokenIdsOfSellerForNFTAdress;   //addressNFT => (address user => tokenId)

    event NFTListed(address indexed nftAddress, address indexed seller,uint256 nftId, uint256 price);
    event NFTDelisted(address indexed nftAddress, uint256 nftId);
    event NFTBought(address indexed nftAddress, address indexed buyer, address indexed seller, uint256 nftId, uint256 price);

    struct Ask {
        address seller; // address of the seller
        uint256 price; // price of the token
    }

    modifier isERC721(address _nftAddress) {
        require(IERC721(_nftAddress).supportsInterface(0x80ac58cd), "Operations: Not ERC721");
        _;
    }
    modifier onlyNFTOwner(address _nftAddress,uint256 _nftId) {
        require(IERC721(_nftAddress).ownerOf(_nftId) == msg.sender, "Not the owner of this one");
        _;
    }

    function setServiceFee(uint256 _value) external onlyOwner {
        serviceFee = _value;
    }

    function setServiceFeeReceiver(address _address) external onlyOwner {
        serviceFeeReceiver = _address;
    }

    function calculateServiceFee(uint256 _price) public view returns (uint256) {
        return (_price * serviceFee) / FEE_RATIO;
    }
    
    function BuyOnSale(address _nftAddress, uint256 _nftId) payable external isERC721(_nftAddress) {
        Ask memory ask =  nftsOnSale[_nftAddress][_nftId];
        uint256 price = ask.price;
        address buyer = msg.sender;
        address seller = ask.seller;

        require(price > 0, "This one is not for sale!");
        require(buyer != seller, "This one is yours already!");
        require(price == msg.value, "The amount is insufficient!");
        require(IERC721(_nftAddress).ownerOf(_nftId) == address(this), "Seller did not give the allowance for us to sell this one.");
        _makeTransaction(_nftAddress,_nftId, seller, buyer, price);

        emit NFTBought(_nftAddress , buyer ,seller ,_nftId, price);
    }

    function putOnSale(address _nftAddress, uint256 _nftId, uint256 _price) external isERC721(_nftAddress) onlyNFTOwner(_nftAddress,_nftId) nonReentrant {
        require(_price > 0 , "price invalid");
        nftsOnSale[_nftAddress][_nftId] =  Ask({seller: msg.sender, price: _price});
        IERC721(_nftAddress).safeTransferFrom(msg.sender, address(this), _nftId);
        _tokenIdsOfSellerForNFTAdress[_nftAddress][msg.sender].add(_nftId);
        emit NFTListed(_nftAddress, msg.sender, _nftId, _price);
    }

    function _cancelSale(address _nftAddress , uint256 _nftId) private {
        require(_tokenIdsOfSellerForNFTAdress[_nftAddress][msg.sender].contains(_nftId), "Order: Token not listed");
        _tokenIdsOfSellerForNFTAdress[_nftAddress][msg.sender].remove(_nftId);
        delete nftsOnSale[_nftAddress][_nftId];
        emit NFTDelisted(_nftAddress,_nftId);
    }

    function cancelSale(address _nftAddress , uint256 _nftId) external isERC721(_nftAddress) onlyNFTOwner(_nftAddress,_nftId) nonReentrant {
        _cancelSale(_nftAddress , _nftId);
    }

    function _makeTransaction(
        address _nftAddress,
        uint256 _nftId,
        address _seller,
        address _buyer,
        uint256 _price
    ) private {
        uint256 fee = calculateServiceFee(_price);
        (bool transferToSeller, ) = _seller.call{value: _price - fee}("");
        require(transferToSeller);

        (bool transferToTreasury, ) = serviceFeeReceiver.call{value: fee}("");
        require(transferToTreasury);
        _cancelSale(_nftAddress , _nftId);
        IERC721(_nftAddress).safeTransferFrom(address(this), _buyer, _nftId);
    }

}