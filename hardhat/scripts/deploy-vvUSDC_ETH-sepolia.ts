import { network } from "hardhat";
const { ethers } = await network.connect();

async function main() {
  // Adresses officielles Sepolia
  const USDC = "0x65aFADD39029741B3b8f0756952C74678c9cEC93";
  const WETH = "0xdd13E55209Fd76AfE204dBda4007C227904f0a81";
  const UNISWAP_ROUTER = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45";

  // Adresse du pool WETH/USDC 0.3% à récupérer dynamiquement
  const UNISWAP_FACTORY = "0x1F98431c8aD98523631AE4a59f267346ea31F984"; // Uniswap V3 Factory Sepolia
  const FEE = 3000;

  // Interface minimale pour getPool
  const factoryAbi = [
    "function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool)"
  ];
  const factory = new ethers.Contract(UNISWAP_FACTORY, factoryAbi, ethers.provider);
  const pool = await factory.getPool(WETH, USDC, FEE);
  if (pool === ethers.ZeroAddress) throw new Error("Pool WETH/USDC 0.3% introuvable sur Sepolia");

  // Déployer vvUSDC_stETH
  const [deployer] = await ethers.getSigners();
  console.log("Déploiement avec l'adresse:", deployer.address);
  const Contract = await ethers.getContractFactory("vvUSDC_stETH");
  const contract = await Contract.deploy(USDC, WETH, UNISWAP_ROUTER, pool);
  await contract.waitForDeployment();
  console.log("Contrat vvUSDC_stETH déployé à:", await contract.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
