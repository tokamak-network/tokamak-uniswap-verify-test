// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Utils} from "./Utils.s.sol";
import {INonfungiblePositionManager} from "./interface/INonfungiblePositionManager.sol";
import {IUniswapV3Factory} from "./interface/IUniswapV3Factory.sol";

contract CreatePool is Script, Utils {
    function createPoolUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            address v3CoreFactoryAddress,
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
        createPool(
            v3CoreFactoryAddress,
            nonfungibleTokenPositionManagerAddress,
            tosAddress,
            usdcAddress,
            usdtAddress,
            wtonAddress,
            tonAddress,
            ethAddress
        );
    }

    function createPool(
        address v3CoreFactoryAddress,
        address nonfungibleTokenPositionManagerAddress,
        address tosAddress,
        address usdcAddress,
        address usdtAddress,
        address,
        address tonAddress,
        address ethAddress
    ) public {
        // get pool address
        // TOSTON, ETHTOS, ETHTON, ETHUSDC, ETHUSDT
        address poolAddressTOSTON = get3000Pool(
            v3CoreFactoryAddress,
            tosAddress,
            tonAddress
        );
        (
            uint160 priceSqrt,
            address token0,
            address token1
        ) = getTONTOSSqrtPriceX96(tosAddress, tonAddress);
        createPool(
            nonfungibleTokenPositionManagerAddress,
            poolAddressTOSTON,
            priceSqrt,
            token0,
            token1
        );

        address poolAddressETHTOS = get3000Pool(
            v3CoreFactoryAddress,
            ethAddress,
            tosAddress
        );
        (priceSqrt, token0, token1) = getETHTOSSqrtPriceX96(
            ethAddress,
            tosAddress
        );
        createPool(
            nonfungibleTokenPositionManagerAddress,
            poolAddressETHTOS,
            priceSqrt,
            token0,
            token1
        );
        address poolAddressETHTON = get3000Pool(
            v3CoreFactoryAddress,
            ethAddress,
            tonAddress
        );
        (priceSqrt, token0, token1) = getETHTONPriceSqrtX96(
            ethAddress,
            tonAddress
        );
        createPool(
            nonfungibleTokenPositionManagerAddress,
            poolAddressETHTON,
            priceSqrt,
            token0,
            token1
        );
        address poolAddressETHUSDC = get3000Pool(
            v3CoreFactoryAddress,
            ethAddress,
            usdcAddress
        );
        (priceSqrt, token0, token1) = getETHUSDCPriceSqrtX96(
            ethAddress,
            usdcAddress
        );
        createPool(
            nonfungibleTokenPositionManagerAddress,
            poolAddressETHUSDC,
            priceSqrt,
            token0,
            token1
        );
        address poolAddressETHUSDT = get3000Pool(
            v3CoreFactoryAddress,
            ethAddress,
            usdtAddress
        );
        (priceSqrt, token0, token1) = getETHUSDTPriceSqrtX96(
            ethAddress,
            usdtAddress
        );
        createPool(
            nonfungibleTokenPositionManagerAddress,
            poolAddressETHUSDT,
            priceSqrt,
            token0,
            token1
        );
    }

    function createPool(
        address nonfungibleTokenPositionManagerAddress,
        address pooladdress,
        uint160 sqrtPriceX96,
        address token0,
        address token1
    ) public {
        if (pooladdress == address(0)) {
            INonfungiblePositionManager nonfungibleTokenPositionManager = INonfungiblePositionManager(
                    payable(nonfungibleTokenPositionManagerAddress)
                );
            console.log("Creating pool...");
            vm.startBroadcast();
            address newPoolAddress = nonfungibleTokenPositionManager
                .createAndInitializePoolIfNecessary(
                    token0,
                    token1,
                    3000,
                    sqrtPriceX96
                );
            vm.stopBroadcast();
            console.log("Pool created: ", newPoolAddress);
        } else {
            console.log(pooladdress, " already exists");
        }
    }

    function get3000Pool(
        address uniswapV3FactoryAddress,
        address address1,
        address address2
    ) public view returns (address) {
        (address token0, address token1) = returnTokens01(address1, address2);
        IUniswapV3Factory v3CoreFactory = IUniswapV3Factory(
            uniswapV3FactoryAddress
        );
        return v3CoreFactory.getPool(token0, token1, 3000);
    }

    function run() external {
        createPoolUsingConfig();
    }
}
