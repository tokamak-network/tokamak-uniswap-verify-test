import "@nomicfoundation/hardhat-toolbox";
import { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    devnetL2: {
      url: "http://localhost:9545",
      chainId: 901,
      accounts: [
        "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
      ],
    },
    hardhat: {
      chains: {
        31337: {
          hardforkHistory: {
            berlin: 10000000,
            london: 20000000,
          },
        },
      },
    },
    localhost: {
      url: "http://127.0.0.1:8546",
      chainId: 31337,
      accounts: [
        "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
      ],
    },
  },
};

export default config;
