// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Utils} from "./Utils.s.sol";
import {LiquidityAmounts} from "./lib/LiquidityAmounts.sol";
import {TickMath} from "./lib/TickMath.sol";
import {SqrtPriceMath} from "./lib/SqrtPriceMath.sol";
import {INonfungiblePositionManager} from "./interface/INonfungiblePositionManager.sol";
import {ISwapRouter02} from "./interface/ISwapRouter02.sol";

contract Swap is Script {
    function swapUsingConfig() public {
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
            address wtonAddress,
            ,
            address ethAddress
        ) = helperConfig.activeNetworkConfig();
        swap(
            swapRouter02,
            tosAddress,
            usdcAddress,
            usdtAddress,
            ethAddress,
            wtonAddress
        );
    }

    function swap(
        address swapRouter02,
        address tosAddress,
        address usdcAddress,
        address usdtAddress,
        address ethAddress,
        address wtonAddress
    ) public {
        IERC20 tos = IERC20(tosAddress);
        IERC20 usdc = IERC20(usdcAddress);
        IERC20 usdt = IERC20(usdtAddress);
        IERC20 wton = IERC20(wtonAddress);
        IERC20 eth = IERC20(ethAddress);
        ISwapRouter02 router = ISwapRouter02(payable(swapRouter02));
        ISwapRouter02.ExactInputSingleParams memory params = ISwapRouter02
            .ExactInputSingleParams({
                tokenIn: address(wton),
                tokenOut: address(eth),
                fee: 3000,
                recipient: address(0xB68AA9E398c054da7EBAaA446292f611CA0CD52B),
                amountIn: 100000000000000,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        vm.startBroadcast();
        router.exactInputSingle{value: 100000000000000}(params);
        vm.stopBroadcast();
    }

    function run() public {
        swapUsingConfig();
    }
}
