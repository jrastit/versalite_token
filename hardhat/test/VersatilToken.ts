import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.connect();

describe("VersatilToken", function () {
  let token0: any;
  let token1: any;
  let router: any;
  let pool: any;
  let versatilToken: any;
  let owner: any;
  let user: any;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();
    // Déployer deux tokens ERC20 mock
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    token0 = await MockERC20.deploy("Token0", "TK0", 18);
    token1 = await MockERC20.deploy("Token1", "TK1", 18);
    // Déployer un pool Uniswap V3 mock
    const MockUniswapV3Pool = await ethers.getContractFactory("MockUniswapV3Pool");
    pool = await MockUniswapV3Pool.deploy(2n ** 96n, token0.target, token1.target);
    // Déployer un router mock
    const MockRouter = await ethers.getContractFactory("MockRouter");
    router = await MockRouter.deploy(token0.target);
    // Déployer VersatilToken
    const VersatilToken = await ethers.getContractFactory("VersatilToken");
    versatilToken = await VersatilToken.deploy(
      token0.target,
      token1.target,
      router.target,
      pool.target,
      "VersatilToken",
      "VVT"
    );
    // Mint des tokens à l'utilisateur
    await token1.mint(user.address, ethers.parseUnits("1000", 18));
  });

  it("should return the correct balance converted via Uniswap", async function () {
    // Le solde converti doit être > 0 si le pool est bien paramétré
    const balance = await versatilToken.balanceOf(user.address);
    expect(balance).to.be.a("bigint");
    expect(balance).to.be.greaterThan(0n);
  });

  it("should allow transfer and emit event", async function () {
    await token1.connect(user).approve(versatilToken.target, ethers.parseUnits("10", 18));
    await expect(
      versatilToken.connect(user).transfer(owner.address, ethers.parseUnits("10", 18))
    ).to.emit(versatilToken, "Transfer");
  });
});
