import { defineConfig } from "hardhat/config";
import hardhatVerify from "@nomicfoundation/hardhat-verify";
import hardhatEthers from "@nomicfoundation/hardhat-ethers";
import "dotenv/config";

export default defineConfig({
  plugins: [hardhatVerify, hardhatEthers],
  solidity: {
    version: "0.8.28",
    settings: { optimizer: { enabled: true, runs: 200 } },
  },

  networks: {
    arbitrum: {
      type: "http",
      url: process.env.ARBITRUM_RPC_URL!,
      // pas nécessaire pour verify, mais ok si tu l'as
      accounts: process.env.ARBITRUM_PRIVATE_KEY
        ? [process.env.ARBITRUM_PRIVATE_KEY]
        : [],
    },
  },

  verify: {
    etherscan: {
      apiKey: process.env.ETHERSCAN_API_KEY!,
    },
  },

});