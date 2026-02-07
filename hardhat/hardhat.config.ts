import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";

const ARBITRUM_RPC_URL = process.env.ARBITRUM_RPC_URL ?? "";
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL ?? "";
const SEPOLIA_PRIVATE_KEY = process.env.SEPOLIA_PRIVATE_KEY ?? "";

export default {
  solidity: {
    version: "0.8.28",
    settings: { optimizer: { enabled: true, runs: 200 } },
  },
  networks: {
    hardhat: ARBITRUM_RPC_URL
      ? { forking: { url: ARBITRUM_RPC_URL /*, blockNumber: 240000000*/ } }
      : {},
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: SEPOLIA_PRIVATE_KEY ? [SEPOLIA_PRIVATE_KEY] : [],
    },
  },
};