// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {ABDKMath64x64} from "../libraries/ABDKMath64x64.sol";
import {TickMath} from "../libraries/TickMath.sol";

contract Utils {
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
