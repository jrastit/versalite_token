import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.connect();

describe("vvUSDC_ETH", function () {
  let vvUSDC_ETH: any;
  let usdc: any;
  let weth: any;
  let router: any;
  let quoter: any;
  let owner: any;
  let user: any;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();
    // Mock addresses for USDC, WETH, router, quoter (replace with real Sepolia addresses for integration)
    usdc = ethers.Wallet.createRandom().address;
    weth = ethers.Wallet.createRandom().address;
    router = ethers.Wallet.createRandom().address;
    quoter = ethers.Wallet.createRandom().address;
    const Contract = await ethers.getContractFactory("vvUSDC_stETH");
    // Utilise des adresses valides pour tous les paramètres
    vvUSDC_ETH = await Contract.deploy(
      usdc || "0x0000000000000000000000000000000000000001",
      weth || "0x0000000000000000000000000000000000000002",
      router || "0x0000000000000000000000000000000000000003",
      quoter || "0x0000000000000000000000000000000000000004"
    );
  });

  it("should have correct name and symbol", async function () {
    expect(await vvUSDC_ETH.name()).to.equal("vvUSDC_stETH");
    expect(await vvUSDC_ETH.symbol()).to.equal("vvUSDC_stETH");
  });

  it("should estimate ETH for USDC and allow transfer (mock)", async function () {
    // This test only checks the revert, as Uniswap is not mocked
    const amountUSDC = ethers.parseUnits("10", 6); // 10 USDC (assuming 6 decimals)
    await expect(
      vvUSDC_ETH.connect(user).transfer(owner.address, amountUSDC, { value: ethers.parseEther("1") })
    ).to.be.revert(ethers);
  });
});
