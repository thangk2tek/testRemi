// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract StakeNFT is ERC721Holder, Ownable ,ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) private userInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 nftId);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 nftId);
    event Harvest(address indexed user, uint256 indexed pid, uint256 nftId);
    event Vesting(address indexed user, uint256 indexed pid, uint256 nftId, uint256 endInvestAt);
    event TokenRecovery(address indexed token, uint256 amount);
    event NonFungibleTokenRecovery(address indexed token, uint256 indexed tokenId);

    struct UserInfo {
        EnumerableSet.UintSet listNFT; 
        uint256 lastDeposit;
        uint256 unclaimed;
    }

    struct PoolInfo {
        IERC721 nftToken; 
        IERC20 tokenReward;
        uint256 blockStart;
        uint256 blockEnd;
        uint256 rewardPerBlock;
        uint256 totalNFTStake;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(IERC721 _nftToken , IERC20 _tokenReward , uint256 _blockStart , uint256 _blockEnd , uint256 _rewardPerBlock) public onlyOwner {
        poolInfo.push(PoolInfo({nftToken: _nftToken  , tokenReward : IERC20(_tokenReward) , blockStart : _blockStart, blockEnd : _blockEnd , rewardPerBlock : _rewardPerBlock , totalNFTStake :0}));
    }

    function updateBlockEndPool(uint256 _pId , uint256  _blockStart, uint256 _blockEnd) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pId];
        pool.blockStart = _blockStart;
        pool.blockEnd  = _blockEnd;
    }

    function calculateReward( uint256 _pid, address _user) public view returns(uint256){
        UserInfo storage user = userInfo[_pid][_user];
        PoolInfo memory pool = poolInfo[_pid];
        uint256 lastBlockStake = block.number ;
        if(pool.blockEnd < block.number){
            lastBlockStake = pool.blockEnd;
        }

        uint256 reward = user.listNFT.length()  * (lastBlockStake - user.lastDeposit) * pool.rewardPerBlock / pool.totalNFTStake;

        return reward;
    }

    function getPoint(uint256 _pid, address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        return user.unclaimed + calculateReward(_pid , _user);
    }

    function deposit(uint256 _pid, uint256 _nftId) public  {
        PoolInfo storage pool = poolInfo[_pid];
        require(block.number >= pool.blockStart , "Not started yet");
        require(block.number <= pool.blockEnd , "Ended yet");
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.listNFT.length() > 0) {
            uint256 unclaim = calculateReward(_pid,msg.sender);
            if (unclaim > 0) {
                user.unclaimed =user.unclaimed + unclaim;
            }
        }

        pool.nftToken.transferFrom(address(msg.sender), address(this), _nftId);
        user.listNFT.add(_nftId);
        pool.totalNFTStake ++;

        user.lastDeposit = block.number;
        emit Deposit(msg.sender, _pid, _nftId);
    }

    function withdraw(uint256 _pid, uint256 _nftId) public nonReentrant   {
        PoolInfo storage pool = poolInfo[_pid];
        require( pool.nftToken.ownerOf(_nftId)  == address(this) , "nft id error");
        UserInfo storage user = userInfo[_pid][msg.sender];
        require( user.listNFT.contains(_nftId) , "nft id error");

        harvest(_pid);

        user.listNFT.remove(_nftId);
        pool.totalNFTStake--;
        pool.nftToken.transferFrom(address(this) , msg.sender, _nftId);
        emit Withdraw(msg.sender, _pid, _nftId);
    }

    function harvest(uint256 _pid) public nonReentrant  {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 pending = calculateReward(_pid,msg.sender);

        uint256 totalHarvest = pending + user.unclaimed;

        if (totalHarvest > 0) {
            require(pool.tokenReward.balanceOf(address(this)) >= totalHarvest, "Invalid quantity") ;
            user.unclaimed = 0;
            user.lastDeposit = block.number; 
            pool.tokenReward.transfer(msg.sender , totalHarvest);
        }

        emit Harvest(msg.sender, _pid, totalHarvest);
    }

    function recoverNonFungibleToken(address _token, uint256 _tokenId) external onlyOwner nonReentrant {
        require(IERC721(_token).ownerOf(_tokenId) == address(this), "token id invalid");
        IERC721(_token).safeTransferFrom(address(this), address(msg.sender), _tokenId);

        emit NonFungibleTokenRecovery(_token, _tokenId);
    }

    function recoverFungibleTokens(address _token) external onlyOwner {
        uint256 amountToRecover = IERC20(_token).balanceOf(address(this));
        require(amountToRecover != 0, "Operations: No token to recover");

        IERC20(_token).transfer(address(msg.sender), amountToRecover);

        emit TokenRecovery(_token, amountToRecover);
    }

}
