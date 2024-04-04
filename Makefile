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

# Define targets for each submodule
v3-core:
	cd v3-core && yarn && cd ..

v3-periphery:
	cd v3-periphery && yarn && cd ..

universal-router: NODE_VERSION=16
universal-router:
	cd universal-router && source ~/.nvm/nvm.sh && nvm use $(NODE_VERSION) && yarn && nvm use default && cd ..

swap-router-contracts:
	cd swap-router-contracts && yarn && cd ..

openzeppelin-contracts:
	cd openzeppelin-contracts && npm install && cd ..

verify: verify-v3-factory verify-v3-periphery verify-swap-router verify-universal-router-permit verify-openzeppelin

network ?= thanossepolia
verify-v3-factory:
	cd v3-core && npx hardhat run scripts/verifyCoreContracts.ts --network ${network} && cd ..

verify-v3-periphery:
	cd v3-periphery && npx hardhat run scripts/verify.ts --network ${network} && cd ..

verify-swap-router:
	cd swap-router-contracts && npx hardhat run scripts/verify.ts --network ${network} && cd ..

verify-universal-router-permit:
	cd universal-router && npx hardhat run scripts/verify.ts --network ${network} && cd ..

verify-openzeppelin:
	cd openzeppelin-contracts && npx hardhat run scripts/verify.js --network ${network} --no-compile && cd ..
verify-pools:
	cd v3-core && npx hardhat run scripts/verifyPools.ts --network ${network} && cd ..

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