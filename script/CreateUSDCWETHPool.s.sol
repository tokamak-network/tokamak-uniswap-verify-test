// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Script, console2} from "forge-std/Script.sol";
import {INonfungiblePositionManager} from "./interface/INonfungiblePositionManager.sol";
import {IUniswapV3Pool} from "./interface/IUniswapV3Pool.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IUniswapV3Factory} from "./interface/IUniswapV3Factory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TickMath} from "./libraries/TickMath.sol";
import {Utils} from "./utils/Utils.sol";

contract CreateUSDCWETHPool is Script, Utils {
    struct PoolInfo {
        address poolAddress;
        uint160 sqrtPriceX96;
        int24 tick;
        address token0;
        address token1;
    }

    function createUSDCWETHPoolUsingConfig(PoolInfo memory mainnetPoolInfo) public {
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
        console2.log(address(ethUsdc3000Pool));
        createUSDCWETHPool(
            mainnetPoolInfo,
            nonfungiblePositionManager,
            v3CoreFactory,
            PoolInfo({
                poolAddress: address(ethUsdc3000Pool),
                sqrtPriceX96: 0,
                tick: 0,
                token0: activeNetworkConfig.ethAddress > activeNetworkConfig.usdcAddress ? activeNetworkConfig.usdcAddress : activeNetworkConfig.ethAddress,
                token1: activeNetworkConfig.ethAddress > activeNetworkConfig.usdcAddress ? activeNetworkConfig.ethAddress : activeNetworkConfig.usdcAddress
            }),
            activeNetworkConfig.ethAddress,
            activeNetworkConfig.usdcAddress
        );
    }

    function nftManagerCreateAndInitialize(INonfungiblePositionManager nonfungiblePositionManager, address token0, address token1, uint24 fee, uint160 sqrtPriceX96) public {
        nonfungiblePositionManager.createAndInitializePoolIfNecessary(token0, token1, fee, sqrtPriceX96);
    }

    function createUSDCWETHPool(
        PoolInfo memory mainnetPoolInfo,
        INonfungiblePositionManager nonfungiblePositionManager,
        IUniswapV3Factory v3CoreFactory,
        PoolInfo memory ethUsdc3000PoolInfo,
        address ethAddress,
        address usdcAddress
    ) public {
        if (ethUsdc3000PoolInfo.poolAddress == address(0)) {
            vm.startBroadcast();
            if (ethUsdc3000PoolInfo.token0 == usdcAddress) nftManagerCreateAndInitialize(nonfungiblePositionManager, usdcAddress, ethAddress, 3000, mainnetPoolInfo.sqrtPriceX96);
            else nftManagerCreateAndInitialize(nonfungiblePositionManager, ethAddress, usdcAddress, 3000, TickMath.getSqrtRatioAtTick(-mainnetPoolInfo.tick));
            vm.stopBroadcast();
            provideLiquidity(ethUsdc3000PoolInfo, nonfungiblePositionManager);
        }
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
        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) =  manager.mint(mintParams);
        vm.stopBroadcast();
        console2.log(tokenId, liquidity, amount0, amount1);
    }

    function run(
        bytes memory mainETHUSDC3000PoolSlot0,
        address mainETHUSDC3000Pooltoken0,
        address mainETHUSDC3000Pooltoken1
    ) external {
        (uint160 mainEthUsdc3000PoolsqrtPriceX96, int24 mainEthUsdc3000Pooltick) = decodeMainnetPoolsInfos(mainETHUSDC3000PoolSlot0);
        PoolInfo memory mainnetPoolInfo = PoolInfo({
            poolAddress: 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8,
            sqrtPriceX96: mainEthUsdc3000PoolsqrtPriceX96,
            tick: mainEthUsdc3000Pooltick,
            token0: mainETHUSDC3000Pooltoken0,
            token1: mainETHUSDC3000Pooltoken1
        });
        createUSDCWETHPoolUsingConfig(mainnetPoolInfo);
    }

        function decodeMainnetPoolsInfos(bytes memory mainEthUsdc3000PoolSlot0) public pure returns (uint160, int24) {
        (
            uint160 mainEthUsdc3000PoolsqrtPriceX96,
            int24 mainEthUsdc3000Pooltick,
            ,,,,
        ) = abi.decode(mainEthUsdc3000PoolSlot0, (uint160, int24, uint16, uint16, uint16, uint8, bool));
        return (mainEthUsdc3000PoolsqrtPriceX96, mainEthUsdc3000Pooltick);
    }
}