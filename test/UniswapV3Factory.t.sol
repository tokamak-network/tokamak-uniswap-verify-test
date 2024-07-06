// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
import {Test, console2} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DevnetConfig} from "./DevnetConfig.t.sol";
import {PoolAddress} from "./libraries/PoolAddress.sol";
import {IUniswapV3Factory} from "./interface/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "./interface/IUniswapV3Pool.sol";
import {ComputePoolAddress} from "./utils/ComputePoolAddress.sol";

contract UniswapV3FactoryTest is StdCheats, Test {
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    IUniswapV3Factory public v3CoreFactory;
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
    address public signer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 public signerPrivateKey =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address public ownerAddress;
    address public wNativeTokenAddress;
    address public ethAddress;

    function setUp() external {
        DevnetConfig devnetConfig = new DevnetConfig();
        (
            address v3CoreFactoryAddress,
            ,
            ,
            address eth,
            address wNativeToken,
            address owner
        ) = devnetConfig.activeNetworkConfig();
        ownerAddress = owner;
        ethAddress = eth;
        wNativeTokenAddress = wNativeToken;
        v3CoreFactory = IUniswapV3Factory(v3CoreFactoryAddress);
    }

    function testFeeTickSpacingValues() public view {
        int24 tickSpacing1 = v3CoreFactory.feeAmountTickSpacing(100);
        int24 tickSpacing10 = v3CoreFactory.feeAmountTickSpacing(500);
        int24 tickSpacing60 = v3CoreFactory.feeAmountTickSpacing(3000);
        int24 tickSpacing200 = v3CoreFactory.feeAmountTickSpacing(10000);

        assertEq(tickSpacing1, 1);
        assertEq(tickSpacing10, 10);
        assertEq(tickSpacing60, 60);
        assertEq(tickSpacing200, 200);
    }

    function testOwnerAddress() public view {
        address owner = v3CoreFactory.owner();
        assertEq(owner, ownerAddress);
    }

    function createAndCheckPool(
        address token0,
        address token1,
        uint24 fee
    ) public {
        if (token0 > token1) {
            (token0, token1) = (token1, token0);
        }
        int24 tickSpacing = v3CoreFactory.feeAmountTickSpacing(fee);
        PoolAddress.PoolKey memory key = PoolAddress.getPoolKey(
            token0,
            token1,
            fee
        );
        address computedAddress = PoolAddress.computeAddress(
            address(v3CoreFactory),
            PoolAddress.getPoolKey(token0, token1, fee)
        );
        vm.expectEmit(true, true, true, true, address(v3CoreFactory));
        emit PoolCreated(
            key.token0,
            key.token1,
            key.fee,
            tickSpacing,
            computedAddress
        );
        address poolAddress = v3CoreFactory.createPool(
            key.token0,
            key.token1,
            key.fee
        );
        console2.log("computedAddress", computedAddress);
        console2.log("poolAddress", poolAddress);
        assertEq(poolAddress, computedAddress);

        vm.expectRevert();
        v3CoreFactory.createPool(key.token0, key.token1, key.fee);
        vm.expectRevert();
        v3CoreFactory.createPool(key.token1, key.token0, key.fee);
        assertEq(
            v3CoreFactory.getPool(key.token0, key.token1, key.fee),
            computedAddress
        );
        assertEq(
            v3CoreFactory.getPool(key.token1, key.token0, key.fee),
            poolAddress
        );
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
        assertEq(pool.factory(), address(v3CoreFactory));
        assertEq(pool.token0(), key.token0);
        assertEq(pool.token1(), key.token1);
        assertEq(pool.fee(), key.fee);
        assertEq(pool.tickSpacing(), tickSpacing);
    }

    function assertPoolAddress(
        address token0,
        address token1,
        uint24 fee
    ) public {
        //get tickSpacing
        int24 tickSpacing = v3CoreFactory.feeAmountTickSpacing(fee);
        PoolAddress.PoolKey memory key = PoolAddress.getPoolKey(
            token0,
            token1,
            fee
        );
        address computedAddress = PoolAddress.computeAddress(
            address(v3CoreFactory),
            PoolAddress.getPoolKey(token0, token1, fee)
        );
        address poolAddress = v3CoreFactory.getPool(
            key.token1,
            key.token0,
            key.fee
        );
        assertEq(poolAddress, computedAddress);

        vm.expectRevert();
        v3CoreFactory.createPool(key.token0, key.token1, key.fee);
        vm.expectRevert();
        v3CoreFactory.createPool(key.token1, key.token0, key.fee);
        assertEq(
            v3CoreFactory.getPool(key.token0, key.token1, key.fee),
            computedAddress
        );
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
        assertEq(pool.factory(), address(v3CoreFactory));
        assertEq(pool.token0(), key.token0);
        assertEq(pool.token1(), key.token1);
        assertEq(pool.fee(), key.fee);
        assertEq(pool.tickSpacing(), tickSpacing);
    }

    function testCreatePoolFee100() public {
        address poolAddress = v3CoreFactory.getPool(
            ethAddress,
            wNativeTokenAddress,
            100
        );
        if (poolAddress == address(0)) {
            createAndCheckPool(ethAddress, wNativeTokenAddress, 100);
        } else {
            assertPoolAddress(ethAddress, wNativeTokenAddress, 100);
        }
    }

    function testCreatePoolFee500() public {
        address poolAddress = v3CoreFactory.getPool(
            ethAddress,
            wNativeTokenAddress,
            500
        );
        if (poolAddress == address(0)) {
            createAndCheckPool(ethAddress, wNativeTokenAddress, 500);
        } else {
            assertPoolAddress(ethAddress, wNativeTokenAddress, 500);
        }
    }

    function testCreatePoolFee3000() public {
        address poolAddress = v3CoreFactory.getPool(
            ethAddress,
            wNativeTokenAddress,
            3000
        );
        if (poolAddress == address(0)) {
            createAndCheckPool(ethAddress, wNativeTokenAddress, 3000);
        } else {
            assertPoolAddress(ethAddress, wNativeTokenAddress, 3000);
        }
    }

    function testCreatePoolFee10000() public {
        address poolAddress = v3CoreFactory.getPool(
            ethAddress,
            wNativeTokenAddress,
            10000
        );
        if (poolAddress == address(0)) {
            createAndCheckPool(ethAddress, wNativeTokenAddress, 10000);
        } else {
            assertPoolAddress(ethAddress, wNativeTokenAddress, 10000);
        }
    }

    function testFailsIfTokenATokenBEqual() public {
        vm.expectRevert();
        createAndCheckPool(ethAddress, ethAddress, 100);
    }

    function testFailsIfTokenA0OrTokenB0() public {
        vm.expectRevert();
        createAndCheckPool(address(0), wNativeTokenAddress, 100);
        vm.expectRevert();
        createAndCheckPool(ethAddress, address(0), 100);
        vm.expectRevert();
        createAndCheckPool(address(0), address(0), 100);
    }

    function testFailsIfFeeAmountIsNotEnabled() public {
        vm.expectRevert();
        createAndCheckPool(ethAddress, wNativeTokenAddress, 200);
    }
}
