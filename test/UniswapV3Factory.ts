// Copyright 2024 justin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import hre, { ethers } from "hardhat";
import NonfungiblePositionManagerABI from "./abis/NonfungiblePositionManager.json";
import UniswapV3FactoryABI from "./abis/UniswapV3Factory.json";
import UniswapV3PoolABI from "./abis/UniswapV3Pool.json";
import { getCreate2Address, UniswapV3PoolBytecode } from "./utils/utils";

describe("UniswapV3Factory test", () => {
  const UniswapV3FactoryAddress = "0x4200000000000000000000000000000000000504";
  const ethAddress = "0x4200000000000000000000000000000000000486";
  const wNativeTokenAddress = "0x4200000000000000000000000000000000000006";
  const ownerAddress = "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720";
  const helpers = require("@nomicfoundation/hardhat-toolbox/network-helpers");
  const NonfungiblePositionManagerAddress =
    "0x4200000000000000000000000000000000000506";
  let signer: SignerWithAddress;
  let ownerSigner: SignerWithAddress;
  let uniswapV3Factory: Contract;
  let nonFungiblePositionManager: Contract;
  let ownerFactory: Contract;
  beforeEach("fork devnetL2", async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: "http://localhost:9545",
            blockNumber: 0,
          },
        },
      ],
    });
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [ownerAddress],
    });
    // send eth to owner
    await hre.network.provider.send("hardhat_setBalance", [
      ownerAddress,
      "0x100000000000000000000000000000000000",
    ]);
    signer = (await ethers.getSigners())[0];
    uniswapV3Factory = await ethers.getContractAt(
      UniswapV3FactoryABI,
      UniswapV3FactoryAddress,
      signer
    );
    nonFungiblePositionManager = await ethers.getContractAt(
      NonfungiblePositionManagerABI,
      NonfungiblePositionManagerAddress,
      signer
    );
    ownerSigner = await ethers.getSigner(ownerAddress);
    ownerFactory = uniswapV3Factory.connect(ownerSigner) as Contract;
  });
  it("get factory address", async () => {
    const factoryAddress = await nonFungiblePositionManager.factory();
    console.log(factoryAddress, UniswapV3FactoryAddress);
    expect(factoryAddress).to.equal(UniswapV3FactoryAddress);
  });
  it("test fee tick spacing values", async () => {
    const tickSpacing1 = await uniswapV3Factory.feeAmountTickSpacing(100);
    const tickSpacing10 = await uniswapV3Factory.feeAmountTickSpacing(500);
    const tickSpacing60 = await uniswapV3Factory.feeAmountTickSpacing(3000);
    const tickSpacing200 = await uniswapV3Factory.feeAmountTickSpacing(10000);

    expect(tickSpacing1).to.equal(1);
    expect(tickSpacing10).to.equal(10);
    expect(tickSpacing60).to.equal(60);
    expect(tickSpacing200).to.equal(200);
  });
  it("test owner adderess", async () => {
    const owner = await uniswapV3Factory.owner();
    expect(owner).to.equal(ownerAddress);
  });
  async function createAndCheckPool(
    token0: string,
    token1: string,
    fee: number
  ) {
    if (token0 > token1) {
      [token0, token1] = [token1, token0];
    }
    const tickSpacing = await uniswapV3Factory.feeAmountTickSpacing(fee);
    const create2Address = getCreate2Address(
      UniswapV3FactoryAddress,
      [token0, token1],
      fee,
      UniswapV3PoolBytecode
    );
    //const create = await uniswapV3Factory.createPool(token0, token1, fee);
    const create =
      await nonFungiblePositionManager.createAndInitializePoolIfNecessary(
        token0,
        token1,
        fee,
        42951287400,
        { gasLimit: 20000000 }
      );

    await expect(create)
      .to.emit(uniswapV3Factory, "PoolCreated")
      .withArgs(token0, token1, fee, tickSpacing, create2Address);

    await expect(uniswapV3Factory.createPool(token0, token1, fee)).to.be
      .reverted;
    await expect(uniswapV3Factory.createPool(token1, token0, fee)).to.be
      .reverted;
    expect(
      await uniswapV3Factory.getPool(token0, token1, fee),
      "getPool in order"
    ).to.equal(create2Address);
    expect(
      await uniswapV3Factory.getPool(token1, token0, fee),
      "getPool in reverse order"
    ).to.equal(create2Address);

    const pool = await ethers.getContractAt(UniswapV3PoolABI, create2Address);
    expect(await pool.factory()).to.equal(UniswapV3FactoryAddress);
    expect(await pool.token0()).to.equal(token0);
    expect(await pool.token1()).to.equal(token1);
    expect(await pool.fee()).to.equal(fee);
    expect(await pool.tickSpacing()).to.equal(tickSpacing);
  }
  describe("#createPool", () => {
    it("succeeds for 100 fee pool", async () => {
      await createAndCheckPool(ethAddress, wNativeTokenAddress, 100);
    });
    it("succeeds for 500 fee pool", async () => {
      await createAndCheckPool(ethAddress, wNativeTokenAddress, 500);
    });
    it("succeeds for 3000 fee pool", async () => {
      const poolAddress = await uniswapV3Factory.getPool(
        ethAddress,
        wNativeTokenAddress,
        3000
      );
      console.log(poolAddress);
      await createAndCheckPool(ethAddress, wNativeTokenAddress, 3000);
    });
    it("succeeds for 10000 fee pool", async () => {
      await createAndCheckPool(ethAddress, wNativeTokenAddress, 10000);
    });
    it("fails if token a == token b", async () => {
      await expect(uniswapV3Factory.createPool(ethAddress, ethAddress, 100)).to
        .be.reverted;
    });
    it("fails if token a is 0 or token b is 0", async () => {
      await expect(
        uniswapV3Factory.createPool(ethAddress, ethers.ZeroAddress, 100)
      ).to.be.reverted;
      await expect(
        uniswapV3Factory.createPool(ethers.ZeroAddress, ethAddress, 100)
      ).to.be.reverted;
      await expect(
        uniswapV3Factory.createPool(ethers.ZeroAddress, ethers.ZeroAddress, 100)
      ).to.be.reverted;
    });
    it("fails if fee amount is not enabled", async () => {
      await expect(
        uniswapV3Factory.createPool(ethAddress, wNativeTokenAddress, 250)
      ).to.be.reverted;
    });
    describe("#setOwner", () => {
      it("fails if caller is not owner", async () => {
        await expect(
          (ownerFactory.connect(signer) as Contract).setOwner(signer.address)
        ).to.be.reverted;
      });

      it("updates owner", async () => {
        await ownerFactory.setOwner(signer.address);
        expect(await ownerFactory.owner()).to.eq(signer.address);
      });

      it("emits event", async () => {
        await expect(ownerFactory.setOwner(signer.address))
          .to.emit(ownerFactory, "OwnerChanged")
          .withArgs(ownerAddress, signer.address);
      });

      it("cannot be called by original owner", async () => {
        await ownerFactory.setOwner(signer.address);
        await expect(ownerFactory.setOwner(ownerAddress)).to.be.reverted;
      });
    });
    describe("#enableFeeAmount", () => {
      it("fails if caller is not owner", async () => {
        await expect(
          (ownerFactory.connect(signer) as Contract).enableFeeAmount(100, 2)
        ).to.be.reverted;
      });
      it("fails if fee is too great", async () => {
        await expect(ownerFactory.enableFeeAmount(1000000, 10)).to.be.reverted;
      });
      it("fails if tick spacing is too small", async () => {
        await expect(ownerFactory.enableFeeAmount(500, 0)).to.be.reverted;
      });
      it("fails if tick spacing is too large", async () => {
        await expect(ownerFactory.enableFeeAmount(500, 16834)).to.be.reverted;
      });
      it("fails if already initialized", async () => {
        await ownerFactory.enableFeeAmount(350, 5);
        await expect(ownerFactory.enableFeeAmount(350, 10)).to.be.reverted;
      });
      it("sets the fee amount in the mapping", async () => {
        await ownerFactory.enableFeeAmount(350, 5);
        expect(await ownerFactory.feeAmountTickSpacing(350)).to.eq(5);
      });
      it("emits an event", async () => {
        await expect(ownerFactory.enableFeeAmount(350, 25))
          .to.emit(ownerFactory, "FeeAmountEnabled")
          .withArgs(350, 25);
      });
      it("enables pool creation", async () => {
        await ownerFactory.enableFeeAmount(250, 15);
        await createAndCheckPool(ethAddress, wNativeTokenAddress, 250);
      });
    });
  });
});
