# Copyright 2024 justin
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
-include .env

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

.PHONY: all v3-core v3-periphery universal-router swap-router-contracts openzeppelin-contracts
# Define install-dependencies target
install-dependencies: v3-core v3-periphery universal-router swap-router-contracts openzeppelin-contracts

### Submodule targets

create-usdc-weth-pool:
	@SLOT1=$$(cast call 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8 "slot0()" --rpc-url $(MAINNET_URL)); \
	SLOT1TOKEN0=$$(cast call 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8 "token0()(address)" --rpc-url $(MAINNET_URL)); \
	SLOT1TOKEN1=$$(cast call 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8 "token1()(address)" --rpc-url $(MAINNET_URL)); \
	forge script script/CreateUSDCWETHPool.s.sol:CreateUSDCWETHPool --fork-url $(TITAN_SEPOLIA_URL) --sig "run(bytes,address,address)" $$SLOT1 $$SLOT1TOKEN0 $$SLOT1TOKEN1 --private-key $(PRIVATE_KEY) --legacy


create-initialize-pools:
	@SLOT1=$$(cast call 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8 "slot0()" --rpc-url $(MAINNET_URL)); \
	SLOT1TOKEN0=$$(cast call 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8 "token0()(address)" --rpc-url $(MAINNET_URL)); \
	SLOT1TOKEN1=$$(cast call 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8 "token1()(address)" --rpc-url $(MAINNET_URL)); \
	SLOT2=$$(cast call 0x1c0cE9aAA0c12f53Df3B4d8d77B82D6Ad343b4E4 "slot0()" --rpc-url $(MAINNET_URL)); \
	SLOT2TOKEN0=$$(cast call 0x1c0cE9aAA0c12f53Df3B4d8d77B82D6Ad343b4E4 "token0()(address)" --rpc-url $(MAINNET_URL)); \
	SLOT2TOKEN1=$$(cast call 0x1c0cE9aAA0c12f53Df3B4d8d77B82D6Ad343b4E4 "token1()(address)" --rpc-url $(MAINNET_URL)); \
	SLOT3=$$(cast call 0xC29271E3a68A7647Fd1399298Ef18FeCA3879F59 "slot0()" --rpc-url $(MAINNET_URL)); \
	SLOT3TOKEN0=$$(cast call 0xC29271E3a68A7647Fd1399298Ef18FeCA3879F59 "token0()(address)" --rpc-url $(MAINNET_URL)); \
	SLOT3TOKEN1=$$(cast call 0xC29271E3a68A7647Fd1399298Ef18FeCA3879F59 "token1()(address)" --rpc-url $(MAINNET_URL)); \
	forge script script/createPoolsAndInitialize.s.sol:CreateAndInitialize --fork-url $(THANOS_SEPOLIA_URL) --sig "run(bytes,address,address,bytes,address,address,bytes,address,address)" $$SLOT1 $$SLOT1TOKEN0 $$SLOT1TOKEN1 $$SLOT2 $$SLOT2TOKEN0 $$SLOT2TOKEN1 $$SLOT3 $$SLOT3TOKEN0 $$SLOT3TOKEN1 --private-key $(PRIVATE_KEY) --broadcast





### Foundry targets
DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY)

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY)
endif
ifeq ($(findstring --network thanossepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(THANOSSEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY)
endif


approve-l1-bridge:
	forge script script/Deposit.s.sol:Approve $(NETWORK_ARGS)


UniswapV3FactoryTest:
	forge test --match-contract UniswapV3FactoryTest --fork-url http://localhost:9546 -vvv

UniswapV3FactoryDeployLocalTest:
	forge test --match-contract UniswapV3FactoryDeployLocalTest -vvv --fork-url http://localhost:8545

Fork9545:
	anvil --fork-url http://localhost:9545 --port 9546