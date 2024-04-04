// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

interface IUsdt {
    function approve(address _spender, uint _value) external;
}

interface bridgeProxyABI {
    function depositERC20(
        address _l1Token,
        address _l2Token,
        uint256 _amount,
        uint32 _l2Gas,
        bytes memory _data
    ) external;

    function depositETH(
        uint32 _minGasLimit, //20000
        bytes calldata _extraData //0x
    ) external payable;
}

contract Approve is Script {
    function approveUsingConfig() public returns (bool, bool, bool) {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            ,
            address usdcBridgeProxy,
            address standardBridgeProxy,
            address tosAddress,
            address usdcAddress,
            address usdtAddress,
            ,
            address tonAddress,

        ) = helperConfig.activeNetworkConfig();
        return
            approve(
                usdcBridgeProxy,
                standardBridgeProxy,
                tosAddress,
                usdcAddress,
                usdtAddress,
                tonAddress
            );
    }

    function approve(
        address usdcBridgeProxy,
        address standardBridgeProxy,
        address tosAddress,
        address usdcAddress,
        address usdtAddress,
        address tonAddress
    ) public returns (bool, bool, bool) {
        console.log("approving...");
        vm.startBroadcast();
        bool success1 = IERC20(usdcAddress).approve(
            usdcBridgeProxy,
            type(uint256).max
        );
        IUsdt(usdtAddress).approve(standardBridgeProxy, type(uint256).max);
        bool success3 = IERC20(tonAddress).approve(
            standardBridgeProxy,
            type(uint256).max
        );
        bool success4 = IERC20(tosAddress).approve(
            standardBridgeProxy,
            type(uint256).max
        );
        vm.stopBroadcast();
        return (success1, success3, success4);
    }

    function run() external {
        (
            bool usdcApproved,
            bool tonApproved,
            bool tosApproved
        ) = approveUsingConfig();
        console.log("usdcApproved, tonApproved, tosApproved");
        console.log(usdcApproved, tonApproved, tosApproved);
    }
}

contract Deposit is Script {
    function depositUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            ,
            address usdcBridgeProxy,
            address standardBridgeProxy,
            address tosAddress,
            address usdcAddress,
            address usdtAddress,
            ,
            address tonAddress,

        ) = helperConfig.activeNetworkConfig();
        HelperConfig.NetworkConfig memory l2NetworkConfig = helperConfig
            .getTitanSepoliaConfig();
        deposit(
            usdcBridgeProxy,
            standardBridgeProxy,
            tosAddress,
            usdcAddress,
            usdtAddress,
            tonAddress,
            l2NetworkConfig.standardBridgeProxy,
            l2NetworkConfig.tosAddress,
            l2NetworkConfig.usdcAddress,
            l2NetworkConfig.usdtAddress,
            l2NetworkConfig.tonAddress
        );
    }

    function deposit(
        address,
        address l1StandardBridgeProxy,
        address l1TosAddress,
        address l1UsdcAddress,
        address l1UsdtAddress,
        address l1TonAddress,
        address,
        address l2TosAddress,
        address l2UsdcAddress,
        address l2UsdtAddress,
        address l2TonAddress
    ) public {
        console.log("deposting...");
        vm.startBroadcast();
        bridgeProxyABI(l1StandardBridgeProxy).depositERC20(
            l1UsdcAddress,
            l2UsdcAddress,
            1000000938000000,
            1000000,
            ""
        );
        bridgeProxyABI(l1StandardBridgeProxy).depositERC20(
            l1TosAddress,
            l2TosAddress,
            1005771000000000000000000,
            1000000,
            ""
        );
        bridgeProxyABI(l1StandardBridgeProxy).depositERC20(
            l1TonAddress,
            l2TonAddress,
            10000000000000000000000000,
            1000000,
            ""
        );
        bridgeProxyABI(l1StandardBridgeProxy).depositERC20(
            l1UsdtAddress,
            l2UsdtAddress,
            1000000938000000,
            1000000,
            ""
        );
        bridgeProxyABI(l1StandardBridgeProxy).depositETH{
            value: 200000000000000000
        }(1000000, "");
        vm.stopBroadcast();
    }

    function run() external {
        depositUsingConfig();
    }
}
