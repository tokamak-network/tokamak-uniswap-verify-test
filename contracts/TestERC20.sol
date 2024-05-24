// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract TestERC20 is ERC20 {
    constructor() ERC20("TestERC20", "TST", 18) {
        totalSupply = 1000000000000000000000000;
        _mint(msg.sender, totalSupply);
    }
}
