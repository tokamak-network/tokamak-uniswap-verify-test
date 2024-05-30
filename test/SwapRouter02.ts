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
import { Contract, ContractTransaction } from "ethers";
import hre, { ethers } from "hardhat";
import NonfungiblePositionManagerABI from "./abis/NonfungiblePositionManager.json";
import SwapRouter02ABI from "./abis/SwapRouter02.json";
import UniswapV3FactoryABI from "./abis/UniswapV3Factory.json";
import WETH9ABI from "./abis/WETH9.json";
import { computePoolAddress } from "./utils/computePoolAddress";
import {
  ADDRESS_THIS,
  FeeAmount,
  MSG_SENDER,
  TICK_SPACINGS,
} from "./utils/constants";
import { encodePriceSqrt } from "./utils/encodePriceSqrt";
import { encodePath } from "./utils/path";
import { getMaxTick, getMinTick } from "./utils/ticks";
describe("UniswapV3SwapRouter02 test", () => {
  const UniswapV3FactoryAddress = "0x4200000000000000000000000000000000000502";
  const SwapRouter02Address = "0x4200000000000000000000000000000000000501";
  const UniswapInterfaceMulticallAddress =
    "0x4200000000000000000000000000000000000509";
  const ethAddress = "0x4200000000000000000000000000000000000486";
  const wNativeTokenAddress = "0x4200000000000000000000000000000000000006";
  const ownerAddress = "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720";
  const helpers = require("@nomicfoundation/hardhat-toolbox/network-helpers");
  const NonfungiblePositionManagerAddress =
    "0x4200000000000000000000000000000000000504";
  let signer: SignerWithAddress;
  let ownerSigner: SignerWithAddress;
  let factory: Contract;
  let nft: Contract;
  let ownerFactory: Contract;
  let router: Contract;
  let weth9: Contract;
  let tokens: any[] = [];
  beforeEach("fork devnetL2", async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: "http://localhost:9545",
            blockNumber: 30,
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
    factory = await ethers.getContractAt(
      UniswapV3FactoryABI,
      UniswapV3FactoryAddress,
      signer
    );
    nft = await ethers.getContractAt(
      NonfungiblePositionManagerABI,
      NonfungiblePositionManagerAddress,
      signer
    );
    ownerSigner = await ethers.getSigner(ownerAddress);
    ownerFactory = factory.connect(ownerSigner) as Contract;
    router = await ethers.getContractAt(
      SwapRouter02ABI,
      SwapRouter02Address,
      signer
    );
    weth9 = await ethers.getContractAt(WETH9ABI, wNativeTokenAddress, signer);
    //tokens.push(await ethers.getContractAt(L2ERC20ABI, ethAddress, signer));
    tokens.push(await ethers.deployContract("TestERC20", signer));
    tokens.push(await ethers.deployContract("TestERC20", signer));
    tokens.push(await ethers.deployContract("TestERC20", signer));
    for (const token of tokens) {
      await token.approve(await router.getAddress(), ethers.MaxUint256);
      await token.approve(await nft.getAddress(), ethers.MaxUint256);
    }
    await weth9.deposit({ value: 1000000000000000000000n });
    await weth9.approve(await router.getAddress(), ethers.MaxUint256);
    await weth9.approve(await nft.getAddress(), ethers.MaxUint256);
  });
  function encodeUnwrapWETH9(amount: number) {
    return router.interface.encodeFunctionData("unwrapWETH9(uint256,address)", [
      amount,
      signer.address,
    ]);
  }
  function encodeSweep(token: string, amount: number, recipient: string) {
    const functionSignature = "sweepToken(address,uint256,address)";
    return router.interface.encodeFunctionData(functionSignature, [
      token,
      amount,
      recipient,
    ]);
  }
  const liquidity = 1000000;
  const getBalances = async (who: string) => {
    const balances = await Promise.all([
      weth9.balanceOf(who),
      tokens[0].balanceOf(who),
      tokens[1].balanceOf(who),
      tokens[2].balanceOf(who),
    ]);
    return {
      weth9: balances[0],
      token0: balances[1],
      token1: balances[2],
      token2: balances[3],
    };
  };
  async function createV3Pool(tokenAddressA: string, tokenAddressB: string) {
    if (tokenAddressA.toLowerCase() > tokenAddressB.toLowerCase())
      [tokenAddressA, tokenAddressB] = [tokenAddressB, tokenAddressA];

    await nft.createAndInitializePoolIfNecessary(
      tokenAddressA,
      tokenAddressB,
      FeeAmount.MEDIUM,
      encodePriceSqrt(1, 1)
    );

    const liquidityParams = {
      token0: tokenAddressA,
      token1: tokenAddressB,
      fee: FeeAmount.MEDIUM,
      tickLower: getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
      tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
      recipient: signer.address,
      amount0Desired: 1000000,
      amount1Desired: 1000000,
      amount0Min: 0,
      amount1Min: 0,
      deadline: 2 ** 32,
    };

    return nft.mint(liquidityParams);
  }
  describe("swaps - v3", () => {
    async function createPoolWETH9(tokenAddress: string) {
      await weth9.deposit({ value: liquidity });
      await weth9.approve(await nft.getAddress(), ethers.MaxUint256);
      return createV3Pool(await weth9.getAddress(), tokenAddress);
    }
    beforeEach("create 0-1 and 1-2 pools", async () => {
      await createV3Pool(
        await tokens[0].getAddress(),
        await tokens[1].getAddress()
      );
      await createV3Pool(
        await tokens[1].getAddress(),
        await tokens[2].getAddress()
      );
    });
    describe("#exactInput", () => {
      async function exactInput(
        tokens: string[],
        amountIn: number = 3,
        amountOutMinimum: number = 1
      ): Promise<ContractTransaction> {
        const inputIsWETH = (await weth9.getAddress()) === tokens[0];
        const outputIsWETH9 =
          tokens[tokens.length - 1] === (await weth9.getAddress());

        const value = inputIsWETH ? amountIn : 0;

        const params = {
          path: encodePath(
            tokens,
            new Array(tokens.length - 1).fill(FeeAmount.MEDIUM)
          ),
          recipient: outputIsWETH9 ? ADDRESS_THIS : MSG_SENDER,
          amountIn,
          amountOutMinimum,
        };

        const data = [
          router.interface.encodeFunctionData("exactInput", [params]),
        ];
        if (outputIsWETH9) {
          data.push(encodeUnwrapWETH9(amountOutMinimum));
        }

        // ensure that the swap fails if the limit is any tighter
        const amountOut = await (
          router.connect(signer) as Contract
        ).exactInput.staticCall(params, { value });
        expect(Number(amountOut)).to.be.eq(amountOutMinimum);

        return (router.connect(signer) as Contract)["multicall(bytes[])"](
          data,
          { value }
        );
      }
      //
      describe("single-pool", () => {
        it("0 -> 1", async () => {
          const pool = await factory.getPool(
            await tokens[0].getAddress(),
            await tokens[1].getAddress(),
            FeeAmount.MEDIUM
          );

          // get balances before
          const poolBefore = await getBalances(pool);
          const signerBefore = await getBalances(signer.address);

          await exactInput([
            await tokens[0].getAddress(),
            await tokens[1].getAddress(),
          ]);

          // get balances after
          const poolAfter = await getBalances(pool);
          const signerAfter = await getBalances(signer.address);

          expect(signerAfter.token0).to.be.eq(signerBefore.token0 - 3n);
          expect(signerAfter.token1).to.be.eq(signerBefore.token1 + 1n);
          expect(poolAfter.token0).to.be.eq(poolBefore.token0 + 3n);
          expect(poolAfter.token1).to.be.eq(poolBefore.token1 - 1n);
        });

        it("1 -> 0", async () => {
          const pool = await factory.getPool(
            await tokens[1].getAddress(),
            await tokens[0].getAddress(),
            FeeAmount.MEDIUM
          );

          // get balances before
          const poolBefore = await getBalances(pool);
          const signerBefore = await getBalances(signer.address);

          await exactInput([
            await tokens[1].getAddress(),
            await tokens[0].getAddress(),
          ]);

          // get balances after
          const poolAfter = await getBalances(pool);
          const signerAfter = await getBalances(signer.address);

          expect(signerAfter.token0).to.be.eq(signerBefore.token0 + 1n);
          expect(signerAfter.token1).to.be.eq(signerBefore.token1 - 3n);
          expect(poolAfter.token0).to.be.eq(poolBefore.token0 - 1n);
          expect(poolAfter.token1).to.be.eq(poolBefore.token1 + 3n);
        });
      });
      describe("multi-pool", () => {
        it("0 -> 1 -> 2", async () => {
          const signerBefore = await getBalances(signer.address);

          await exactInput(
            [
              await tokens[0].getAddress(),
              await tokens[1].getAddress(),
              await tokens[2].getAddress(),
            ],
            5,
            1
          );

          const signerAfter = await getBalances(signer.address);

          expect(signerAfter.token0).to.be.eq(signerBefore.token0 - 5n);
          expect(signerAfter.token2).to.be.eq(signerBefore.token2 + 1n);
        });

        it("2 -> 1 -> 0", async () => {
          const signerBefore = await getBalances(signer.address);

          await exactInput(
            [
              await tokens[0].getAddress(),
              await tokens[1].getAddress(),
              await tokens[2].getAddress(),
            ],
            5,
            1
          );

          const signerAfter = await getBalances(signer.address);

          expect(signerAfter.token2).to.be.eq(signerBefore.token2 + 1n);
          expect(signerAfter.token0).to.be.eq(signerBefore.token0 - 5n);
        });

        it("events", async () => {
          await expect(
            exactInput(
              [
                await tokens[0].getAddress(),
                await tokens[1].getAddress(),
                await tokens[2].getAddress(),
              ],
              5,
              1
            )
          )
            .to.emit(tokens[0], "Transfer")
            .withArgs(
              signer.address,
              computePoolAddress(
                await factory.getAddress(),
                [await tokens[0].getAddress(), await tokens[1].getAddress()],
                FeeAmount.MEDIUM
              ),
              5
            )
            .to.emit(tokens[1], "Transfer")
            .withArgs(
              computePoolAddress(
                await factory.getAddress(),
                [await tokens[0].getAddress(), await tokens[1].getAddress()],
                FeeAmount.MEDIUM
              ),
              await router.getAddress(),
              3
            )
            .to.emit(tokens[1], "Transfer")
            .withArgs(
              await router.getAddress(),
              computePoolAddress(
                await factory.getAddress(),
                [await tokens[1].getAddress(), await tokens[2].getAddress()],
                FeeAmount.MEDIUM
              ),
              3
            )
            .to.emit(tokens[2], "Transfer")
            .withArgs(
              computePoolAddress(
                await factory.getAddress(),
                [await tokens[1].getAddress(), await tokens[2].getAddress()],
                FeeAmount.MEDIUM
              ),
              signer.address,
              1
            );
        });
      });
      describe("ETH input", () => {
        describe("WETH9", () => {
          beforeEach(async () => {
            await createPoolWETH9(await tokens[0].getAddress());
          });

          it("WETH9 -> 0", async () => {
            const pool = await factory.getPool(
              await weth9.getAddress(),
              await tokens[0].getAddress(),
              FeeAmount.MEDIUM
            );

            // get balances before
            const poolBefore = await getBalances(pool);
            const signerBefore = await getBalances(signer.address);

            await expect(
              exactInput([
                await weth9.getAddress(),
                await tokens[0].getAddress(),
              ])
            )
              .to.emit(weth9, "Deposit")
              .withArgs(await router.getAddress(), 3);

            // get balances after
            const poolAfter = await getBalances(pool);
            const signerAfter = await getBalances(signer.address);

            expect(signerAfter.token0).to.be.eq(signerBefore.token0 + 1n);
            expect(poolAfter.weth9).to.be.eq(poolBefore.weth9 + 3n);
            expect(poolAfter.token0).to.be.eq(poolBefore.token0 - 1n);
          });

          it("WETH9 -> 0 -> 1", async () => {
            const signerBefore = await getBalances(signer.address);

            await expect(
              exactInput(
                [
                  await weth9.getAddress(),
                  await tokens[0].getAddress(),
                  await tokens[1].getAddress(),
                ],
                5
              )
            )
              .to.emit(weth9, "Deposit")
              .withArgs(await router.getAddress(), 5);

            const signerAfter = await getBalances(signer.address);

            expect(signerAfter.token1).to.be.eq(signerBefore.token1 + 1n);
          });
        });
      });
    });
  });
});
