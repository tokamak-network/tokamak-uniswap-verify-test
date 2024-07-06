// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Script, console} from "forge-std/Script.sol";

contract HelperConfig is Script {
    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/
    struct NetworkConfig {
        address v3CoreFactoryAddress;
        address nonfungibleTokenPositionManagerAddress;
        address swapRouter02;
        address usdcBridgeProxy;
        address standardBridgeProxy;
        address tosAddress;
        address usdcAddress;
        address usdtAddress;
        address wtonAddress;
        address tonAddress;
        address ethAddress;
    }
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    NetworkConfig private activeNetworkConfig;

    constructor() {
        uint256 chainId = block.chainid;
        if (chainId == 111551118080) {
            activeNetworkConfig = getDeprecatedThanosSepoliaConfig();
        } else if (chainId == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else if (chainId == 55007) {
            activeNetworkConfig = getTitanSepoliaConfig();
        } else if (chainId == 111551119090) {
            activeNetworkConfig = getThanosSepoliaConfig();
        } else {
            console.log("Unsupported chainId: %d", chainId);
        }
    }

    function getActiveNetworkConfig() external view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

    function getMainnetConfig() public view returns (NetworkConfig memory mainnetConfig){
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/state.mainnet.json");
        string memory json = vm.readFile(path);
        mainnetConfig = NetworkConfig({
            v3CoreFactoryAddress: address(0),
            nonfungibleTokenPositionManagerAddress: address(0),
            swapRouter02: address(0),
            usdcBridgeProxy: address(0),
            standardBridgeProxy: address(0),
            tosAddress: vm.parseJsonAddress(json, ".tosAddress"),
            usdcAddress: vm.parseJsonAddress(json, ".usdcAddress"),
            usdtAddress: address(0),
            wtonAddress: vm.parseJsonAddress(json, ".wtonAddress"),
            tonAddress: address(0),
            ethAddress: vm.parseJsonAddress(json, ".weth9Address")
        });
    }

    function getSepoliaConfig() public view returns (NetworkConfig memory sepoliaConfig) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/state.sepolia.json");
        string memory json = vm.readFile(path);
        sepoliaConfig = 
            NetworkConfig({
                v3CoreFactoryAddress: address(0),
                nonfungibleTokenPositionManagerAddress: address(0),
                swapRouter02: address(0),
                usdcBridgeProxy: vm.parseJsonAddress(json, ".usdcBridgeProxy"),
                standardBridgeProxy: vm.parseJsonAddress(
                    json,
                    ".standardBridgeProxy"
                ),
                tosAddress: vm.parseJsonAddress(json, ".tosAddress"),
                usdcAddress: vm.parseJsonAddress(json, ".usdcAddress"),
                usdtAddress: vm.parseJsonAddress(json, ".usdtAddress"),
                wtonAddress: vm.parseJsonAddress(json, ".wtonAddress"),
                tonAddress: vm.parseJsonAddress(json, ".tonAddress"),
                ethAddress: vm.parseJsonAddress(json, ".wethAddress")
            });
    }

    function getTitanSepoliaConfig()
        public
        view
        returns (NetworkConfig memory titanSepoliaConfig)
    {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/state.titansepolia.json");
        string memory json = vm.readFile(path);
        titanSepoliaConfig = 
            NetworkConfig({
                v3CoreFactoryAddress: vm.parseJsonAddress(
                    json,
                    ".v3CoreFactoryAddress"
                ),
                nonfungibleTokenPositionManagerAddress: vm.parseJsonAddress(
                    json,
                    ".nonfungibleTokenPositionManagerAddress"
                ),
                swapRouter02: vm.parseJsonAddress(json, ".swapRouter02"),
                usdcBridgeProxy: address(0),
                standardBridgeProxy: address(0),
                tosAddress: vm.parseJsonAddress(json, ".TOS"),
                usdcAddress: vm.parseJsonAddress(json, ".USDC"),
                usdtAddress: vm.parseJsonAddress(json, ".USDT"),
                wtonAddress: vm.parseJsonAddress(json, ".TON"),
                tonAddress: vm.parseJsonAddress(json, ".TON"),
                ethAddress: vm.parseJsonAddress(json, ".WETH")
            });
    }

    function getThanosSepoliaConfig() public view returns (NetworkConfig memory thanosSepoliaConfig) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/state.thanossepolia.json");
        string memory json = vm.readFile(path);
        thanosSepoliaConfig = NetworkConfig({
            v3CoreFactoryAddress: vm.parseJsonAddress(json, ".UniswapV3Factory"),
            nonfungibleTokenPositionManagerAddress: vm.parseJsonAddress(json, ".NonfungiblePositionManager"),
            swapRouter02: vm.parseJsonAddress(json, ".QuoterV2"),
            usdcBridgeProxy: vm.parseJsonAddress(json, ".l2usdcBridge"),
            standardBridgeProxy: vm.parseJsonAddress(json, ".l2standardBridge"),
            tosAddress: vm.parseJsonAddress(json, ".tosAddress"),
            usdcAddress: vm.parseJsonAddress(json, ".usdcAddress"),
            usdtAddress: vm.parseJsonAddress(json, ".usdtAddress"),
            wtonAddress: vm.parseJsonAddress(json, ".wtonAddress"),
            tonAddress: address(0),
            ethAddress: vm.parseJsonAddress(json, ".ERC20ETH")
        });
    }

    function getDeprecatedThanosSepoliaConfig()
        public
        view
        returns (NetworkConfig memory deprecatedThanosSepoliaConfig)
    {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/state.thanossepolia.deprecated.json");
        string memory json = vm.readFile(path);
        deprecatedThanosSepoliaConfig =
            NetworkConfig({
                v3CoreFactoryAddress: vm.parseJsonAddress(
                    json,
                    ".v3CoreFactoryAddress"
                ),
                nonfungibleTokenPositionManagerAddress: vm.parseJsonAddress(
                    json,
                    ".nonfungibleTokenPositionManagerAddress"
                ),
                swapRouter02: vm.parseJsonAddress(json, ".swapRouter02"),
                usdcBridgeProxy: vm.parseJsonAddress(json, ".usdcBridgeProxy"),
                standardBridgeProxy: address(0),
                tosAddress: vm.parseJsonAddress(json, ".tosAddress"),
                usdcAddress: vm.parseJsonAddress(json, ".usdcAddress"),
                usdtAddress: vm.parseJsonAddress(json, ".usdtAddress"),
                wtonAddress: vm.parseJsonAddress(json, ".wtonAddress"),
                tonAddress: address(0),
                ethAddress: vm.parseJsonAddress(json, ".ethAddress")
            });
    }
}
