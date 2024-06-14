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
.PHONY: all v3-core v3-periphery universal-router swap-router-contracts openzeppelin-contracts
# Define install-dependencies target
install-dependencies: v3-core v3-periphery universal-router swap-router-contracts openzeppelin-contracts

# Define targets for each submodule
v3-core:
	cd v3-core && yarn && cd ..

v3-periphery:
	cd v3-periphery && yarn && cd ..

universal-router: NODE_VERSION=16
universal-router:
	cd universal-router && source ~/.nvm/nvm.sh && nvm use $(NODE_VERSION) && yarn && forge install && nvm use default && cd ..

swap-router-contracts:
	cd swap-router-contracts && yarn && cd ..

openzeppelin-contracts:
	cd openzeppelin-contracts && npm install && cd ..

verify: verify-v3-factory verify-v3-periphery verify-swap-router verify-universal-router-permit verify-openzeppelin

NETWORKS := thanossepolia thanossepolianightly

verify-v3-factory:
	for network in $(NETWORKS); do \
		cd v3-core && npx hardhat run scripts/verifyCoreContracts.ts --network $$network && cd ..; \
	done

verify-v3-periphery:
	for network in $(NETWORKS); do \
		cd v3-periphery && npx hardhat run scripts/verify.ts --network $$network && cd ..; \
	done

verify-swap-router:
	for network in $(NETWORKS); do \
		cd swap-router-contracts && npx hardhat run scripts/verify.ts --network $$network && cd ..; \
	done

verify-universal-router:
	for network in $(NETWORKS); do \
		cd universal-router && npx hardhat run scripts/verify.ts --network $$network && cd ..; \
	done

verify-openzeppelin:
	for network in $(NETWORKS); do \
		cd openzeppelin-contracts && npx hardhat run scripts/verify.js --network $$network --no-compile && cd ..; \
	done