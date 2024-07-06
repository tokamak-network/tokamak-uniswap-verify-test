// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Test, console2} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DevnetConfig} from "./DevnetConfig.t.sol";
import {PoolAddress} from "./libraries/PoolAddress.sol";
import {INonfungiblePositionManager} from "./interface/INonfungiblePositionManager.sol";
import {IUniswapV3Factory} from "./interface/IUniswapV3Factory.sol";
import {TestERC200} from "./utils/TestERC200.sol";
import {Utils} from "./utils/Utils.sol";

contract NonfungiblePositionManagerTest is StdCheats, Test, Utils {
    DevnetConfig devnetConfig;
    INonfungiblePositionManager public nonfungiblePositionManager;
    address public wNativeTokenAddress;
    address public ethAddress;
    IUniswapV3Factory public v3CoreFactory;
    address public token0;
    address public token1;
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    function setUp() external {
        devnetConfig = new DevnetConfig();
        devnetConfig = new DevnetConfig();
        (
            address v3CoreFactoryAddress,
            address nonfungibleTokenPositionManagerAddress,
            ,
            address eth,
            address wNativeToken,
            
        ) = devnetConfig.activeNetworkConfig();
        wNativeTokenAddress = wNativeToken;
        ethAddress = eth;
        v3CoreFactory = IUniswapV3Factory(v3CoreFactoryAddress);
        nonfungiblePositionManager = INonfungiblePositionManager(
            payable(nonfungibleTokenPositionManagerAddress)
        );
        token0 = address(new TestERC200("Token0", "Token0"));
        token1 = address(new TestERC200("Token1", "Token1"));
        if (token0 > token1) {
            (token0, token1) = (token1, token0);
        }
    }

    function testCreatesThePoolAtExpectedAddress() public {
        PoolAddress.PoolKey memory key = PoolAddress.getPoolKey(
            token0,
            token1,
            3000
        );
        address computedAddress = PoolAddress.computeAddress(
            address(v3CoreFactory),
            key
        );
        // const code = await wallet.provider.getCode(expectedAddress)
        bytes memory code = computedAddress.code;
        assertEq(code, bytes(""));

        nonfungiblePositionManager.createAndInitializePoolIfNecessary(
            token0,
            token1,
            3000,
            sqrtP(1, 1)
        );
        bytes memory codeAfter = computedAddress.code;
        assertGt(codeAfter.length, 0);
    }
    function testIfItisPayable() public {
        nonfungiblePositionManager.createAndInitializePoolIfNecessary{value: 1}(
            token0,
            token1,
            3000,
            sqrtP(1, 1)
        );
    }

    function testWorksIfPoolIsCreatedButNotInitialized() public {
        PoolAddress.PoolKey memory key = PoolAddress.getPoolKey(
            token0,
            token1,
            3000
        );
        address computedAddress = PoolAddress.computeAddress(
            address(v3CoreFactory),
            key
        );

        address poolAddress = v3CoreFactory.createPool(
            key.token0,
            key.token1,
            key.fee
        );
        bytes memory code = computedAddress.code;
        nonfungiblePositionManager.createAndInitializePoolIfNecessary(
            token0,
            token1,
            3000,
            sqrtP(2, 1)
        );
    }
}
