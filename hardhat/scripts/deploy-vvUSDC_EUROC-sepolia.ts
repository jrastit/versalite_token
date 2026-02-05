import { network } from "hardhat";
const { ethers } = await network.connect();

async function main() {
  // Adresses officielles Sepolia
  const USDC = "0x65aFADD39029741B3b8f0756952C74678c9cEC93";
  const EUROC = "0x6a0A6C5e0B6e2D0F2eC3e6eC7e5e2e0F2eC3e6eC"; // Remplacer par l'adresse officielle EUROC Sepolia
  const UNISWAP_ROUTER = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45";

  // Adresse du pool USDC/EUROC 0.3% à récupérer dynamiquement
  const UNISWAP_FACTORY = "0x1F98431c8aD98523631AE4a59f267346ea31F984"; // Uniswap V3 Factory Sepolia
  const FEE = 3000;

  // Interface minimale pour getPool
  const factoryAbi = [
    "function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool)"
  ];
  const factory = new ethers.Contract(UNISWAP_FACTORY, factoryAbi, ethers.provider);
  const pool = await factory.getPool(USDC, EUROC, FEE);
  if (pool === ethers.ZeroAddress) throw new Error("Pool USDC/EUROC 0.3% introuvable sur Sepolia");

  // Déployer VersatilToken générique (v_token0/v_token1)
  const [deployer] = await ethers.getSigners();
  console.log("Déploiement avec l'adresse:", deployer.address);
  const Contract = await ethers.getContractFactory("VersatilToken");
  const name = "v_token0";
  const symbol = "v_token1";
  const contract = await Contract.deploy(USDC, EUROC, UNISWAP_ROUTER, pool, name, symbol);
  await contract.waitForDeployment();
  console.log("Contrat VersatilToken déployé à:", await contract.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
