// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ABDKMath64x64} from "./ABDKMath64x64.sol";
import {console, Script} from "forge-std/Script.sol";
import {TickMath} from "./lib/TickMath.sol";

contract Utils is Script {
    function getTONTOSSqrtPriceX96(
        address wtonAddress,
        address tosAddress
    ) public pure returns (uint160, address, address) {
        //1 WTON = 1.09956 TOS
        //1 TOS = 0.90946 WTON
        // both are 18 decimals
        (address token0, address token1) = returnTokens01(
            wtonAddress,
            tosAddress
        );
        int128 reserve0;
        int128 reserve1;
        uint160 priceSqrt;
        if (token0 == wtonAddress) {
            reserve0 = int128(909460000000000000);
            reserve1 = int128(1000000000000000000);
            priceSqrt = sqrtP(reserve0, reserve1);
        } else {
            reserve0 = int128(1000000000000000000);
            reserve1 = int128(909460000000000000);
            priceSqrt = sqrtP(reserve0, reserve1);
        }
        return (priceSqrt, token0, token1);
    }

    function getETHTOSSqrtPriceX96(
        address ethAddress,
        address tosAddress
    ) public pure returns (uint160, address, address) {
        // 1 TOS = 0.00068 ETH
        // 1 ETH = 1,471.67 TOS
        // both are 18 decimals
        (address token0, address token1) = returnTokens01(
            ethAddress,
            tosAddress
        );
        int128 reserve0;
        int128 reserve1;
        uint160 priceSqrt;
        if (token0 == tosAddress) {
            reserve0 = int128(1000000000000000000);
            reserve1 = int128(681000000000000);
            priceSqrt = sqrtP(reserve0, reserve1);
        } else {
            reserve0 = int128(681000000000000);
            reserve1 = int128(1000000000000000000);
            priceSqrt = sqrtP(reserve0, reserve1);
        }
        return (priceSqrt, token0, token1);
    }

    function getETHTONPriceSqrtX96(
        address ethAddress,
        address wtonAddress
    ) public pure returns (uint160, address, address) {
        // 1 WTON = 0.00074 ETH
        // 1 ETH = 1,351.29 WTON
        // both are 18 decimals
        (address token0, address token1) = returnTokens01(
            wtonAddress,
            ethAddress
        );
        int128 reserve0;
        int128 reserve1;
        uint160 priceSqrt;
        if (token0 == wtonAddress) {
            reserve0 = int128(1000000000000000000);
            reserve1 = int128(740000000000000);
            priceSqrt = sqrtP(reserve0, reserve1);
        } else {
            reserve0 = int128(740000000000000);
            reserve1 = int128(1000000000000000000);
            priceSqrt = sqrtP(reserve0, reserve1);
        }
        return (priceSqrt, token0, token1);
    }

    function getETHUSDCPriceSqrtX96(
        address ethAddress,
        address usdcAddress
    ) public pure returns (uint160, address, address) {
        // 1 USDC = 0.0003 ETH
        // 1 ETH = 3,927.77 USDC
        // both are 18 decimals
        (address token0, address token1) = returnTokens01(
            usdcAddress,
            ethAddress
        );
        int128 reserve0;
        int128 reserve1;
        uint160 priceSqrt;
        if (token0 == usdcAddress) {
            reserve0 = int128(1000000);
            reserve1 = int128(300000000000000);
            priceSqrt = sqrtP(reserve0, reserve1);
        } else {
            reserve0 = int128(300000000000000);
            reserve1 = int128(1000000);
            priceSqrt = sqrtP(reserve0, reserve1);
        }
        return (priceSqrt, token0, token1);
    }

    function getETHUSDTPriceSqrtX96(
        address ethAddress,
        address usdtAddress
    ) public pure returns (uint160, address, address) {
        // 1 USDT = 0.00025 ETH
        // 1 ETH = 3,927.77 USDT
        // both are 18 decimals
        int128 reserve0;
        int128 reserve1;
        (address token0, address token1) = returnTokens01(
            usdtAddress,
            ethAddress
        );
        uint160 priceSqrt;
        if (token0 == usdtAddress) {
            reserve0 = int128(1000000);
            reserve1 = int128(300000000000000);
            priceSqrt = sqrtP(reserve0, reserve1);
        } else {
            reserve0 = int128(300000000000000);
            reserve1 = int128(1000000);
            priceSqrt = sqrtP(reserve0, reserve1);
        }
        return (priceSqrt, token0, token1);
    }

    function sqrtP(
        int128 reserve0,
        int128 reserve1
    ) internal pure returns (uint160) {
        return
            uint160(
                int160(
                    ABDKMath64x64.sqrt(
                        int128(int256(ABDKMath64x64.div(reserve1, reserve0)))
                    ) << (96 - 64)
                )
            );
    }

    function divRound(
        int128 x,
        int128 y
    ) internal pure returns (int128 result) {
        int128 quot = ABDKMath64x64.div(x, y);
        result = quot >> 64;

        // Check if remainder is greater than 0.5
        if (quot % 2 ** 64 >= 0x8000000000000000) {
            result += 1;
        }
    }

    function nearestUsableTick(
        int24 tick_,
        uint24 tickSpacing
    ) internal pure returns (int24 result) {
        result =
            int24(divRound(int128(tick_), int128(int24(tickSpacing)))) *
            int24(tickSpacing);

        if (result < TickMath.MIN_TICK) {
            result += int24(tickSpacing);
        } else if (result > TickMath.MAX_TICK) {
            result -= int24(tickSpacing);
        }
    }

    function tick(uint160 sqrtPriceX96) internal pure returns (int24 tick_) {
        tick_ = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
    }

    function returnTokens01(
        address token0,
        address token1
    ) public pure returns (address, address) {
        if (token0 < token1) {
            return (token0, token1);
        } else {
            return (token1, token0);
        }
    }
}
