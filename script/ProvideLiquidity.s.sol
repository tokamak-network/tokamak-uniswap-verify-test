// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Script, console2} from "forge-std/Script.sol";
import {INonfungiblePositionManager} from "./interface/INonfungiblePositionManager.sol";
import {IUniswapV3Pool} from "./interface/IUniswapV3Pool.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IUniswapV3Factory} from "./interface/IUniswapV3Factory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Utils} from "./utils/Utils.sol";

contract ProvideLiquidity is Script, Utils {
    struct PoolInfo {
        address poolAddress;
        uint160 sqrtPriceX96;
        int24 tick;
        address token0;
        address token1;
    }

    function provideLiquidityUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory activeNetworkConfig = helperConfig.getActiveNetworkConfig();
        INonfungiblePositionManager nonfungiblePositionManager;
         nonfungiblePositionManager = INonfungiblePositionManager(
            payable(activeNetworkConfig.nonfungibleTokenPositionManagerAddress)
        );
        IUniswapV3Factory v3CoreFactory = IUniswapV3Factory(activeNetworkConfig.v3CoreFactoryAddress);
        IUniswapV3Pool ethUsdc3000Pool = IUniswapV3Pool(
            v3CoreFactory.getPool(
                activeNetworkConfig.ethAddress,
                activeNetworkConfig.usdcAddress,
                3000
            )
        );
        IUniswapV3Pool tosTon3000Pool = IUniswapV3Pool(
            v3CoreFactory.getPool(
                activeNetworkConfig.tosAddress,
                activeNetworkConfig.wtonAddress,
                3000
            )
        );
        IUniswapV3Pool ethTon3000Pool = IUniswapV3Pool(
            v3CoreFactory.getPool(
                activeNetworkConfig.ethAddress,
                activeNetworkConfig.wtonAddress,
                3000
            )
        );
        (uint160 sqrtPriceX96, int24 tick, address token0, address token1) = returnSqrtPriceX96AndTick(ethUsdc3000Pool);
        PoolInfo memory ethUsdcPoolInfo = PoolInfo({
            poolAddress: address(ethUsdc3000Pool),
            sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            token0: token0,
            token1: token1
        });
        (sqrtPriceX96, tick, token0, token1) = returnSqrtPriceX96AndTick(tosTon3000Pool);
        PoolInfo memory tosTonPoolInfo = PoolInfo({
            poolAddress: address(tosTon3000Pool),
            sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            token0: token0,
            token1: token1
        });
        (sqrtPriceX96, tick, token0, token1) = returnSqrtPriceX96AndTick(ethTon3000Pool);
        PoolInfo memory ethTonPoolInfo = PoolInfo({
            poolAddress: address(ethTon3000Pool),
            sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            token0: token0,
            token1: token1
        });
        // ** broadcast
        provideLiquidity(ethUsdcPoolInfo, nonfungiblePositionManager);
        provideLiquidity(tosTonPoolInfo, nonfungiblePositionManager);
        provideLiquidity(ethTonPoolInfo, nonfungiblePositionManager);
    }

    function provideLiquidity(PoolInfo memory pool, INonfungiblePositionManager manager) public {
        // ** approve
        uint256 allowanceToken0 = IERC20(pool.token0).allowance(msg.sender, address(manager));
        uint256 allowanceToken1 = IERC20(pool.token1).allowance(msg.sender, address(manager));
        uint256 balanceToken0 = IERC20(pool.token0).balanceOf(msg.sender);
        uint256 balanceToken1 = IERC20(pool.token1).balanceOf(msg.sender);
        if(allowanceToken0 < balanceToken0) {
            vm.startBroadcast();
            IERC20(pool.token0).approve(address(manager), type(uint256).max);
            vm.stopBroadcast();
        }
        if(allowanceToken1 < balanceToken1) {
            vm.startBroadcast();
            IERC20(pool.token1).approve(address(manager), type(uint256).max);
            vm.stopBroadcast();
        }

        // ** provide
        int24 tickDifference = 6900;
        uint24 fee = 3000;
        uint24 tickSpacing = 60;
        INonfungiblePositionManager.MintParams memory mintParams = INonfungiblePositionManager.MintParams({
            token0: pool.token0,
            token1: pool.token1,
            fee: fee,
            tickLower: nearestUsableTick(pool.tick - tickDifference, tickSpacing),
            tickUpper: nearestUsableTick(pool.tick + tickDifference, tickSpacing),
            amount0Desired: IERC20(pool.token0).balanceOf(msg.sender) / 3,
            amount1Desired: IERC20(pool.token1).balanceOf(msg.sender) / 3,
            amount0Min: 0,
            amount1Min: 0,
            recipient: msg.sender,
            deadline: block.timestamp + 1000
        });
        vm.startBroadcast();
        manager.mint(mintParams);
        vm.stopBroadcast();
    }

    function returnSqrtPriceX96AndTick(IUniswapV3Pool pool) public view returns (uint160, int24, address, address) {
        (uint160 sqrtPriceX96,
            int24 tick,
            ,
            ,
            ,
            ,
            ) = pool.slot0();
        address token0 = pool.token0();
        address token1 = pool.token1();
        return (sqrtPriceX96, tick, token0, token1);
    }

    function run() external {
        provideLiquidityUsingConfig();
    }
}