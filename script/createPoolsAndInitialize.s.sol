// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Script, console2} from "forge-std/Script.sol";
import {INonfungiblePositionManager} from "./interface/INonfungiblePositionManager.sol";
import {IUniswapV3Pool} from "./interface/IUniswapV3Pool.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IUniswapV3Factory} from "./interface/IUniswapV3Factory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TickMath} from "./libraries/TickMath.sol";
import {FullMath} from "./libraries/FullMath.sol";
import {Utils} from "./utils/Utils.sol";

interface IName {
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract CreateAndInitialize is Script, Utils {
    struct PoolInfo {
        address poolAddress;
        uint160 sqrtPriceX96;
        int24 tick;
        address token0;
        address token1;
    }

    function createAndInitializeUsingConfig(PoolInfo memory mainnetETHUSDC, PoolInfo memory mainnetTOSTON, PoolInfo memory mainnetETHTON) public {
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
        createAndInitialize(
            mainnetETHUSDC,
            mainnetTOSTON,
            mainnetETHTON,
            nonfungiblePositionManager,
            v3CoreFactory,
            PoolInfo({
                poolAddress: address(ethUsdc3000Pool),
                sqrtPriceX96: 0,
                tick: 0,
                token0: activeNetworkConfig.ethAddress > activeNetworkConfig.usdcAddress ? activeNetworkConfig.usdcAddress : activeNetworkConfig.ethAddress,
                token1: activeNetworkConfig.ethAddress > activeNetworkConfig.usdcAddress ? activeNetworkConfig.ethAddress : activeNetworkConfig.usdcAddress
            }),
            PoolInfo({
                poolAddress: address(tosTon3000Pool),
                sqrtPriceX96: 0,
                tick: 0,
                token0: activeNetworkConfig.tosAddress > activeNetworkConfig.wtonAddress ? activeNetworkConfig.wtonAddress : activeNetworkConfig.tosAddress,
                token1: activeNetworkConfig.tosAddress > activeNetworkConfig.wtonAddress ? activeNetworkConfig.tosAddress : activeNetworkConfig.wtonAddress
            }),
            PoolInfo({
                poolAddress: address(ethTon3000Pool),
                sqrtPriceX96: 0,
                tick: 0,
                token0: activeNetworkConfig.ethAddress > activeNetworkConfig.wtonAddress ? activeNetworkConfig.wtonAddress : activeNetworkConfig.ethAddress,
                token1: activeNetworkConfig.ethAddress > activeNetworkConfig.wtonAddress ? activeNetworkConfig.ethAddress : activeNetworkConfig.wtonAddress
            }),
            activeNetworkConfig.ethAddress,
            activeNetworkConfig.usdcAddress,
            activeNetworkConfig.wtonAddress,
            activeNetworkConfig.tosAddress
        );
    }

    function nftManagerCreateAndInitialize(INonfungiblePositionManager nonfungiblePositionManager, address token0, address token1, uint24 fee, uint160 sqrtPriceX96) public {
        nonfungiblePositionManager.createAndInitializePoolIfNecessary(token0, token1, fee, sqrtPriceX96);
    }

    function sqrtPriceX96ToUint(uint160 sqrtPriceX96, uint8 decimalsToken0)
    internal pure returns (uint256)
    {
        uint256 numerator1 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        uint256 numerator2 = 10**decimalsToken0;
        return FullMath.mulDiv(numerator1, numerator2, 1 << 192);
    }

    function handleETHUSDC(INonfungiblePositionManager nonfungiblePositionManager, PoolInfo memory mainnetETHUSDC, PoolInfo memory ethUSDC3000Pool, address ethAddress, address usdcAddress) public {
        // mainnet token0 = USDC
        // mainnet token1 = WETH9
        vm.startBroadcast();
        if (ethUSDC3000Pool.token0 == usdcAddress) nftManagerCreateAndInitialize(nonfungiblePositionManager, usdcAddress, ethAddress, 3000, mainnetETHUSDC.sqrtPriceX96);
        else nftManagerCreateAndInitialize(nonfungiblePositionManager, ethAddress, usdcAddress, 3000, TickMath.getSqrtRatioAtTick(-mainnetETHUSDC.tick));
        vm.stopBroadcast();
    }

    function handleTOSTON(INonfungiblePositionManager nonfungiblePositionManager, PoolInfo memory mainnetTOSTON, PoolInfo memory tosTon300Pool, address tosAddress, address tonAddress) public {
        // mainnet token0 = TOS
        // mainnet token1 = TON
        uint price = sqrtPriceX96ToUint(mainnetTOSTON.sqrtPriceX96, 18) / (10 ** 9);
        uint160 sqrtPriceX96 = sqrtP(int128(int256(10**18)), int128(int256(price)));
        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
        vm.startBroadcast();
        if(tosTon300Pool.token0 == tosAddress) nftManagerCreateAndInitialize(nonfungiblePositionManager, tosAddress, tonAddress, 3000, sqrtPriceX96);
        else nftManagerCreateAndInitialize(nonfungiblePositionManager, tonAddress, tosAddress, 3000, TickMath.getSqrtRatioAtTick(-tick));
        vm.stopBroadcast();
    }

    function handleTONETH(INonfungiblePositionManager nonfungiblePositionManager, PoolInfo memory mainnetETHTON, PoolInfo memory ethTon3000Pool, address ethAddress, address tonAddress) public {
        // mainnet token0 = WETH9
        // mainnet token1 = TON
        uint price = sqrtPriceX96ToUint(mainnetETHTON.sqrtPriceX96, 18) / (10 ** 9);
        uint160 sqrtPriceX96 = sqrtP(int128(int256(10**18)), int128(int256(price)));
        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
        vm.startBroadcast();
        if(ethTon3000Pool.token0 == ethAddress) nftManagerCreateAndInitialize(nonfungiblePositionManager, ethAddress, tonAddress, 3000, sqrtPriceX96);
        else nftManagerCreateAndInitialize(nonfungiblePositionManager, tonAddress, ethAddress, 3000, TickMath.getSqrtRatioAtTick(-tick));
        vm.stopBroadcast();
    }

    function createAndInitialize(PoolInfo memory mainnetETHUSDC, PoolInfo memory mainnetTOSTON, PoolInfo memory mainnetETHTON, INonfungiblePositionManager nonfungiblePositionManager, IUniswapV3Factory v3CoreFactory, PoolInfo memory ethUSDC3000Pool, PoolInfo memory tosTon300Pool, PoolInfo memory ethTon3000Pool, address ethAddress, address usdcAddress, address tonAddress, address tosAddress
    ) public {
        handleETHUSDC(nonfungiblePositionManager, mainnetETHUSDC, ethUSDC3000Pool, ethAddress, usdcAddress);
        handleTOSTON(nonfungiblePositionManager, mainnetTOSTON, tosTon300Pool, tosAddress, tonAddress);
        handleTONETH(nonfungiblePositionManager, mainnetETHTON, ethTon3000Pool, ethAddress, tonAddress);
    }

    function decodeMainnetPoolsInfos(bytes memory mainEthUsdc3000PoolSlot0,
            bytes memory mainEthTon3000PoolSlot0,
            bytes memory mainTosTon3000PoolSlot0) public pure returns(uint160, int24, uint160, int24, uint160, int24) 
            {
                (
                    uint160 mainEthUsdc3000PoolsqrtPriceX96,
                    int24 mainEthUsdc3000Pooltick,
                    ,,,,
                ) = abi.decode(mainEthUsdc3000PoolSlot0, (uint160, int24, uint16, uint16, uint16, uint8, bool));
                (
                    uint160 mainEthTon3000PoolsqrtPriceX96,
                    int24 mainEthTon3000Pooltick,
                    ,,,,
                ) = abi.decode(mainEthTon3000PoolSlot0, (uint160, int24, uint16, uint16, uint16, uint8, bool));
                (
                    uint160 mainTosTon3000PoolsqrtPriceX96,
                    int24 mainTosTon3000Pooltick,
                    ,,,,
                ) = abi.decode(mainTosTon3000PoolSlot0, (uint160, int24, uint16, uint16, uint16, uint8, bool));
                return (mainEthUsdc3000PoolsqrtPriceX96, mainEthUsdc3000Pooltick, mainEthTon3000PoolsqrtPriceX96, mainEthTon3000Pooltick, mainTosTon3000PoolsqrtPriceX96, mainTosTon3000Pooltick);
            }
    

    function run(            
            bytes memory mainEthUsdc3000PoolSlot0,
            address mainEthUsdc3000Pooltoken0,
            address mainEthUsdc3000Pooltoken1,
            bytes memory mainEthTon3000PoolSlot0,
            address mainEthTon3000Pooltoken0,
            address mainEthTon3000Pooltoken1,
            bytes memory mainTosTon3000PoolSlot0,
            address mainTosTon3000Pooltoken0,
            address mainTosTon3000Pooltoken1
            ) external {
            (uint160 mainEthUsdc3000PoolsqrtPriceX96, int24 mainEthUsdc3000Pooltick, uint160 mainEthTon3000PoolsqrtPriceX96, int24 mainEthTon3000Pooltick, uint160 mainTosTon3000PoolsqrtPriceX96, int24 mainTosTon3000Pooltick) = decodeMainnetPoolsInfos(mainEthUsdc3000PoolSlot0, mainEthTon3000PoolSlot0, mainTosTon3000PoolSlot0);
        createAndInitializeUsingConfig(
            PoolInfo({
                poolAddress: address(0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8),
                sqrtPriceX96: mainEthUsdc3000PoolsqrtPriceX96,
                tick: mainEthUsdc3000Pooltick,
                token0: mainEthUsdc3000Pooltoken0,
                token1: mainEthUsdc3000Pooltoken1
            }),
            PoolInfo({
                poolAddress: address(0xC29271E3a68A7647Fd1399298Ef18FeCA3879F59),
                sqrtPriceX96: mainEthTon3000PoolsqrtPriceX96,
                tick: mainEthTon3000Pooltick,
                token0: mainEthTon3000Pooltoken0,
                token1: mainEthTon3000Pooltoken1
            }),
            PoolInfo({
                poolAddress: address(0x1c0cE9aAA0c12f53Df3B4d8d77B82D6Ad343b4E4),
                sqrtPriceX96: mainTosTon3000PoolsqrtPriceX96,
                tick: mainTosTon3000Pooltick,
                token0: mainTosTon3000Pooltoken0,
                token1: mainTosTon3000Pooltoken1
            })
        );
    }
}