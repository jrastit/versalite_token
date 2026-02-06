import { network } from "hardhat";
const { ethers } = await network.connect();

async function main() {
  // Adresses officielles Arbitrum
  const USDC = "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8";
  // const USDC = "0xaf88d065e77c8cC2239327C5EDb3A432268e5831"; 
  const WETH = "0x82af49447d8a07e3bd95bd0d56f35241523fbab1";
  const UNISWAP_POOL = "0xc31e54c7a869b9fcbecc14363cf510d1c41fa443"; // Pool WETH/USDC 0.3% à récupérer dynamiquement
  const UNISWAP_ROUTER = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45";

  const FEE = 3000;

  // Déployer VersatilToken
  const [deployer] = await ethers.getSigners();
  console.log("Déploiement avec l'adresse:", deployer.address);
  const Contract = await ethers.getContractFactory("VersatilToken");
  const name = "vUSDC_WETH";
  const symbol = "vUSDC_WETH";
  const contract = await Contract.deploy(USDC, WETH, UNISWAP_ROUTER, UNISWAP_POOL, name, symbol);
  await contract.waitForDeployment();
  console.log("Contrat VersatilToken déployé à:", await contract.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
