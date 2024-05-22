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
import { expect } from "chai";
import { Contract } from "ethers";
import hre, { ethers } from "hardhat";
import NonfungiblePositionManagerABI from "./abis/NonfungiblePositionManager.json";
import UniswapV3FactoryABI from "./abis/UniswapV3Factory.json";
import UniswapV3PoolABI from "./abis/UniswapV3Pool.json";
import { getCreate2Address, UniswapV3PoolBytecode } from "./Utils/utils";

describe("UniswapV3Factory test", () => {
  const UniswapV3FactoryAddress = "0x4200000000000000000000000000000000000504";
  const ethAddress = "0x4200000000000000000000000000000000000486";
  const wNativeTokenAddress = "0x4200000000000000000000000000000000000006";
  const ownerAddress = "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720";
  const NonfungiblePositionManagerAddress =
    "0x4200000000000000000000000000000000000506";
  let signer;
  let uniswapV3Factory: Contract;
  let nonFungiblePositionManager: Contract;
  it("setUp", async () => {
    signer = (await ethers.getSigners())[0];
    uniswapV3Factory = await ethers.getContractAt(
      UniswapV3FactoryABI,
      UniswapV3FactoryAddress,
      signer
    );
    const provider = new ethers.JsonRpcProvider("http://localhost:9545");
    console.log(await provider.getBalance(ownerAddress));
    nonFungiblePositionManager = await ethers.getContractAt(
      NonfungiblePositionManagerABI,
      NonfungiblePositionManagerAddress,
      signer
    );
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
        600,
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
      await expect(uniswapV3Factory.createPool(ethAddress, "0x", 100)).to.be
        .reverted;
      await expect(uniswapV3Factory.createPool("0x", ethAddress, 100)).to.be
        .reverted;
      await expect(uniswapV3Factory.createPool("0x", "0x", 100)).to.be.reverted;
    });
    it("fails if fee amount is not enabled", async () => {
      await expect(
        uniswapV3Factory.createPool(ethAddress, wNativeTokenAddress, 250)
      ).to.be.reverted;
    });
    it("impersonate owner and send tx", async () => {
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [ownerAddress],
      });
      // send eth to owner
      await hre.network.provider.send("hardhat_setBalance", [
        ownerAddress,
        "0x100000000000000000000000000000000000",
      ]);
      const ownerSigner = await ethers.getSigner(ownerAddress);
      const ownerFactory: Contract = uniswapV3Factory.connect(
        ownerSigner
      ) as Contract;
      const tx = await ownerFactory.enableFeeAmount(100, 1);
      const receipt = await tx.wait();
      console.log(receipt);
    });
  });
});
