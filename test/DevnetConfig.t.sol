// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {console} from "forge-std/Test.sol";

contract DevnetConfig {
    NetworkConfig public activeNetworkConfig;
    struct NetworkConfig {
        address v3CoreFactoryAddress;
        address nonfungibleTokenPositionManagerAddress;
        address swapRouter02Address;
        address ethAddress;
        address wNativeTokenAddress;
        address ownerAddress;
    }

    constructor() {
        uint256 chainId = block.chainid;
        if (chainId == 901) {
            activeNetworkConfig = getDevnetConfig();
        } else {
            console.log("Unsupported chainId: %d", chainId);
        }
    }

    function getDevnetConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                v3CoreFactoryAddress: 0x4200000000000000000000000000000000000504,
                nonfungibleTokenPositionManagerAddress: 0x4200000000000000000000000000000000000506,
                swapRouter02Address: 0x4200000000000000000000000000000000000503,
                ethAddress: 0x4200000000000000000000000000000000000486,
                wNativeTokenAddress: 0x4200000000000000000000000000000000000006,
                ownerAddress: 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
            });
    }
}
