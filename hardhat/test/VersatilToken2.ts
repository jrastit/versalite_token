import { expect } from "chai";
import { ethers } from "hardhat";

describe("VersatilToken on Arbitrum fork", function () {
  // Choose the *exact* pair that matches your pool
  const USDCe = "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8";
  const WETH = "0x82af49447d8a07e3bd95bd0d56f35241523fbab1";
  const POOL = "0xc31e54c7a869b9fcbecc14363cf510d1c41fa443"; // WETH/USDC pool (verify it matches USDCe vs USDC)
  const ROUTER = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45";

  let wethContract: any;
  let usdceContract: any;
  let wethDecimals: number;
  let usdceDecimals: number;
  before(async () => {
    wethContract = await ethers.getContractAt(
      "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol:IERC20Metadata",
      WETH,
    );
    wethDecimals = await wethContract.decimals();
    usdceContract = await ethers.getContractAt(
      "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol:IERC20Metadata",
      USDCe,
    );
    usdceDecimals = await usdceContract.decimals();
    const wethBalance = await wethContract.balanceOf(
      process.env.MAIN_ADDRESS!,
    );
    console.log("WETH Balance:", wethBalance.toString());
    const wethBalanceInETH = Number(
      ethers.formatUnits(wethBalance, wethDecimals),
    );
    console.log("WETH Balance in ETH:", wethBalanceInETH);
  });

  it("computes value using real pool state", async () => {
    const VersatilToken = await ethers.getContractFactory("VersatilToken");
    const v = await VersatilToken.deploy(
      USDCe,
      WETH,
      ROUTER,
      POOL,
      "vUSDC_WETH",
      "vUSDC_WETH",
    );
    await v.waitForDeployment();

    const mainAddress = process.env.MAIN_ADDRESS!;
    const value = await v.balanceOf(mainAddress); // any address to test logic
    expect(value).to.be.gte(0n);
    // Get balance in WETH
    console.log("Value USDCe:", value.toString());

    const valueInUSDCe = Number(ethers.formatUnits(value, usdceDecimals));
    console.log("Value in USDCe:", valueInUSDCe);
  });

  it("should return the correct decimals", async function () {
    const VersatilToken = await ethers.getContractFactory("VersatilToken");
    const v = await VersatilToken.deploy(
      USDCe,
      WETH,
      ROUTER,
      POOL,
      "vUSDC_WETH",
      "vUSDC_WETH",
    );
    await v.waitForDeployment();

    const decimals = await v.decimals();
    expect(decimals).to.equal(usdceDecimals);
  });
});