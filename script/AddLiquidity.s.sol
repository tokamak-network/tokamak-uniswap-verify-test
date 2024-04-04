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

contract AddLiquidity is Script, Utils {
    function addLiquidityUsingConfig() public {
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
            ,
            address ethAddress
        ) = helperConfig.activeNetworkConfig();
        addLiquidity(
            nonfungibleTokenPositionManagerAddress,
            tosAddress,
            usdcAddress,
            usdtAddress,
            ethAddress,
            wtonAddress
        );
    }

    function addLiquidity(
        address nonfungibleTokenPositionManagerAddress,
        address tosAddress,
        address usdcAddress,
        address usdtAddress,
        address ethAddress,
        address wtonAddress
    ) public {
        (
            uint160 sqrtPriceX96,
            address token0,
            address token1
        ) = getTONTOSSqrtPriceX96(tosAddress, wtonAddress);
        // mint(
        //     nonfungibleTokenPositionManagerAddress,
        //     sqrtPriceX96,
        //     token0,
        //     token1
        // );
        // (sqrtPriceX96, token0, token1) = getETHTOSSqrtPriceX96(
        //     ethAddress,
        //     tosAddress
        // );
        // mintOneTokenIsETH(
        //     nonfungibleTokenPositionManagerAddress,
        //     sqrtPriceX96,
        //     token0,
        //     token1,
        //     ethAddress
        // );
        // (sqrtPriceX96, token0, token1) = getETHTONPriceSqrtX96(
        //     ethAddress,
        //     wtonAddress
        // );
        // mintOneTokenIsETH(
        //     nonfungibleTokenPositionManagerAddress,
        //     sqrtPriceX96,
        //     token0,
        //     token1,
        //     ethAddress
        // );
        // (sqrtPriceX96, token0, token1) = getETHUSDCPriceSqrtX96(
        //     ethAddress,
        //     usdcAddress
        // );
        // mintOneTokenIsETH(
        //     nonfungibleTokenPositionManagerAddress,
        //     sqrtPriceX96,
        //     token0,
        //     token1,
        //     ethAddress
        // );
        (sqrtPriceX96, token0, token1) = getETHUSDTPriceSqrtX96(
            ethAddress,
            usdtAddress
        );
        mintOneTokenIsETH(
            nonfungibleTokenPositionManagerAddress,
            sqrtPriceX96,
            token0,
            token1,
            ethAddress
        );
    }

    function mintOneTokenIsETH(
        address nonfungibleTokenPositionManagerAddress,
        uint160 sqrtPriceX96,
        address token0,
        address token1,
        address ethAddress
    ) public {
        int24 currentTick = tick(sqrtPriceX96);
        int24 tickLower = nearestUsableTick(currentTick - 5108, 60);
        uint256 balance0 = token0 == ethAddress
            ? address(0xB68AA9E398c054da7EBAaA446292f611CA0CD52B).balance
            : IERC20(token0).balanceOf(
                0xB68AA9E398c054da7EBAaA446292f611CA0CD52B
            );
        uint256 balance1 = token1 == ethAddress
            ? address(0xB68AA9E398c054da7EBAaA446292f611CA0CD52B).balance
            : IERC20(token1).balanceOf(
                0xB68AA9E398c054da7EBAaA446292f611CA0CD52B
            );
        uint256 amount0Desired = balance0 < balance1
            ? balance0 / 5
            : balance1 / 5;
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmount0(
            TickMath.getSqrtRatioAtTick(tickLower),
            sqrtPriceX96,
            amount0Desired
        );
        uint160 nextSqrtPrice = SqrtPriceMath
            .getNextSqrtPriceFromAmount0RoundingUp(
                sqrtPriceX96,
                liquidity,
                amount0Desired,
                false
            );
        uint256 deadline = block.timestamp + 3000;
        int256 amount1Desired = SqrtPriceMath.getAmount1Delta(
            sqrtPriceX96,
            nextSqrtPrice,
            int128(liquidity)
        );
        INonfungiblePositionManager nonfungibleTokenPositionManager = INonfungiblePositionManager(
                payable(nonfungibleTokenPositionManagerAddress)
            );
        INonfungiblePositionManager.MintParams
            memory mintParams = INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: 3000,
                tickLower: tickLower,
                tickUpper: nearestUsableTick(
                    TickMath.getTickAtSqrtRatio(nextSqrtPrice),
                    60
                ),
                amount0Desired: amount0Desired,
                amount1Desired: uint256(amount1Desired),
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(0xB68AA9E398c054da7EBAaA446292f611CA0CD52B),
                deadline: deadline
            });
        vm.startBroadcast();
        nonfungibleTokenPositionManager.mint{
            value: ethAddress == token0
                ? amount0Desired
                : uint256(amount1Desired)
        }(mintParams);
        vm.stopBroadcast();
    }

    function mint(
        address nonfungibleTokenPositionManagerAddress,
        uint160 sqrtPriceX96,
        address token0,
        address token1
    ) public {
        int24 currentTick = tick(sqrtPriceX96);
        int24 tickLower = nearestUsableTick(currentTick - 5108, 60);
        uint256 balance0 = IERC20(token0).balanceOf(
            0xB68AA9E398c054da7EBAaA446292f611CA0CD52B
        );
        uint256 balance1 = IERC20(token1).balanceOf(
            0xB68AA9E398c054da7EBAaA446292f611CA0CD52B
        );
        uint256 amount0Desired = balance0 < balance1
            ? balance0 / 3
            : balance1 / 3;
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmount0(
            TickMath.getSqrtRatioAtTick(tickLower),
            sqrtPriceX96,
            amount0Desired
        );
        uint160 nextSqrtPrice = SqrtPriceMath
            .getNextSqrtPriceFromAmount0RoundingUp(
                sqrtPriceX96,
                liquidity,
                amount0Desired,
                false
            );
        uint256 deadline = block.timestamp + 3000;
        int256 amount1Desired = SqrtPriceMath.getAmount1Delta(
            sqrtPriceX96,
            nextSqrtPrice,
            int128(liquidity)
        );
        INonfungiblePositionManager nonfungibleTokenPositionManager = INonfungiblePositionManager(
                payable(nonfungibleTokenPositionManagerAddress)
            );
        INonfungiblePositionManager.MintParams
            memory mintParams = INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: 3000,
                tickLower: tickLower,
                tickUpper: nearestUsableTick(
                    TickMath.getTickAtSqrtRatio(nextSqrtPrice),
                    60
                ),
                amount0Desired: amount0Desired,
                amount1Desired: uint256(amount1Desired),
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(0xB68AA9E398c054da7EBAaA446292f611CA0CD52B),
                deadline: deadline
            });
        vm.startBroadcast();
        nonfungibleTokenPositionManager.mint(mintParams);
        vm.stopBroadcast();
    }

    function run() public {
        addLiquidityUsingConfig();
    }
}
