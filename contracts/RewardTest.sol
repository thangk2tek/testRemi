// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardTest is ERC20 {
    constructor() ERC20("RewardTest", "RewardTest") {
        _mint(msg.sender, 200_000_000 ether);
    }
}
