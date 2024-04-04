// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Utils} from "./Utils.s.sol";

contract ApproveNFTManager is Script {
    function approveUsingConfig()
        public
        returns (bool, bool, bool, bool, bool)
    {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            address nonfungibleTokenPositionManagerAddress,
            ,
            ,
            ,
            address tosAddress,
            address usdcAddress,
            address usdtAddress,
            address wtonAddress,
            address tonAddress,
            address ethAddress
        ) = helperConfig.activeNetworkConfig();
        return
            approve(
                nonfungibleTokenPositionManagerAddress,
                tosAddress,
                usdcAddress,
                usdtAddress,
                ethAddress,
                tonAddress
            );
    }

    function approve(
        address nonfungibleTokenPositionManagerAddress,
        address tosAddress,
        address usdcAddress,
        address usdtAddress,
        address ethAddress,
        address wtonAddress
    ) public returns (bool, bool, bool, bool, bool) {
        vm.startBroadcast();
        bool success1 = IERC20(usdcAddress).approve(
            nonfungibleTokenPositionManagerAddress,
            type(uint256).max
        );
        bool success2 = IERC20(usdtAddress).approve(
            nonfungibleTokenPositionManagerAddress,
            type(uint256).max
        );
        bool success3 = IERC20(ethAddress).approve(
            nonfungibleTokenPositionManagerAddress,
            type(uint256).max
        );
        bool success4 = IERC20(tosAddress).approve(
            nonfungibleTokenPositionManagerAddress,
            type(uint256).max
        );

        bool success5 = IERC20(wtonAddress).approve(
            nonfungibleTokenPositionManagerAddress,
            type(uint256).max
        );
        vm.stopBroadcast();
        return (success1, success2, success3, success4, success5);
    }

    function run() external {
        (
            bool usdcApproved,
            bool usdtApproved,
            bool ethApproved,
            bool tosApproved,
            bool wtonApproved
        ) = approveUsingConfig();
        console.log("usdcApproved, tonApproved, tosApproved, wtonApproved");
        console.log(usdcApproved, usdtApproved, ethApproved, tosApproved);
        console.log(wtonApproved);
    }
}

contract ApproveL1Bridge is Script {
    function approveUsingConfig()
        public
        returns (bool, bool, bool, bool, bool)
    {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            ,
            ,
            address bridge,
            address tosAddress,
            address usdcAddress,
            address usdtAddress,
            ,
            address tonAddress,
            address ethAddress
        ) = helperConfig.activeNetworkConfig();
        return
            approve(
                bridge,
                tosAddress,
                usdcAddress,
                usdtAddress,
                ethAddress,
                tonAddress
            );
    }

    function approve(
        address bridge,
        address tosAddress,
        address usdcAddress,
        address usdtAddress,
        address ethAddress,
        address tonAddress
    ) public returns (bool, bool, bool, bool, bool) {
        console.log("approving...");
        vm.startBroadcast();
        bool success1 = IERC20(usdcAddress).approve(bridge, type(uint256).max);
        bool success2 = IERC20(usdtAddress).approve(bridge, type(uint256).max);
        bool success3 = IERC20(ethAddress).approve(bridge, type(uint256).max);
        bool success4 = IERC20(tosAddress).approve(bridge, type(uint256).max);
        bool success5 = IERC20(tonAddress).approve(bridge, type(uint256).max);
        vm.stopBroadcast();
        return (success1, success2, success3, success4, success5);
    }

    function run() external {
        (
            bool usdcApproved,
            bool usdtApproved,
            bool ethApproved,
            bool tosApproved,
            bool tonApproved
        ) = approveUsingConfig();
        console.log("usdcApproved, tonApproved, tosApproved, tonApproved");
        console.log(usdcApproved, usdtApproved, ethApproved, tosApproved);
        console.log(tonApproved);
    }
}

contract ApproveSwapRouter02 is Script {
    function approveUsingConfig()
        public
        returns (bool, bool, bool, bool, bool)
    {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address swapRouter02,
            ,
            ,
            address tosAddress,
            address usdcAddress,
            address usdtAddress,
            ,
            address tonAddress,
            address ethAddress
        ) = helperConfig.activeNetworkConfig();
        return
            approve(
                swapRouter02,
                tosAddress,
                usdcAddress,
                usdtAddress,
                ethAddress,
                tonAddress
            );
    }

    function approve(
        address swapRouter02,
        address tosAddress,
        address usdcAddress,
        address usdtAddress,
        address ethAddress,
        address wtonAddress
    ) public returns (bool, bool, bool, bool, bool) {
        console.log("approving...");
        vm.startBroadcast();
        bool success1 = IERC20(usdcAddress).approve(
            swapRouter02,
            type(uint256).max
        );
        bool success2 = IERC20(usdtAddress).approve(
            swapRouter02,
            type(uint256).max
        );
        bool success3 = IERC20(ethAddress).approve(
            swapRouter02,
            type(uint256).max
        );
        bool success4 = IERC20(tosAddress).approve(
            swapRouter02,
            type(uint256).max
        );
        bool success5 = IERC20(wtonAddress).approve(
            swapRouter02,
            type(uint256).max
        );
        vm.stopBroadcast();
        return (success1, success2, success3, success4, success5);
    }

    function run() external {
        (
            bool usdcApproved,
            bool usdtApproved,
            bool ethApproved,
            bool tosApproved,
            bool wtonApproved
        ) = approveUsingConfig();
        console.log("usdcApproved, tonApproved, tosApproved, wtonApproved");
        console.log(usdcApproved, usdtApproved, ethApproved, tosApproved);
        console.log(wtonApproved);
    }
}
