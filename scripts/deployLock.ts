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
import { ethers } from "hardhat";
async function main() {
  // We get the contract to deploy
  const Lock = await ethers.getContractFactory("Lock");
  const lock = await Lock.deploy(21321321321321);

  console.log("Lock deployed to:", await lock.getAddress());

  const tx = await lock.writeFunction(123, { gasLimit: 20000000 });
  const receipt = await tx.wait();
  const aa = await lock.aa();
  console.log(aa.toString());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
