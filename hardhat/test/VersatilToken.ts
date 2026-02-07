import { expect } from "chai";
import { ethers } from "hardhat";

describe("VersatilToken", function () {
  let token0: any;
  let token1: any;
  let router: any;
  let pool: any;
  let versatilToken: any;
  let owner: any;
  let user: any;

  const ratio = 25n; // token1 vaut 25x token0
  const amount = 1000n;

  function sqrtBigInt(value: bigint): bigint {
    if (value < 0n) throw new Error("negative");
    if (value < 2n) return value;
    let x0 = value / 2n;
    let x1 = (x0 + value / x0) / 2n;
    while (x1 < x0) {
      x0 = x1;
      x1 = (x0 + value / x0) / 2n;
    }
    return x0;
  }

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    const MockERC20 = await ethers.getContractFactory("MockERC20");

    token0 = await MockERC20.deploy("Token0", "TK0", 18);
    await token0.waitForDeployment();

    token1 = await MockERC20.deploy("Token1", "TK1", 18);
    await token1.waitForDeployment();

    const token0Addr = await token0.getAddress();
    const token1Addr = await token1.getAddress();

    const sqrtRatio = sqrtBigInt(ratio);
    const sqrtPriceX96 = sqrtRatio * (2n ** 96n);

    const MockUniswapV3Pool = await ethers.getContractFactory("MockUniswapV3Pool");
    pool = await MockUniswapV3Pool.deploy(sqrtPriceX96, token0Addr, token1Addr);
    await pool.waitForDeployment();
    const poolAddr = await pool.getAddress();

    const MockRouter = await ethers.getContractFactory("MockRouter");
    router = await MockRouter.deploy(token0Addr);
    await router.waitForDeployment();
    const routerAddr = await router.getAddress();

    const VersatilToken = await ethers.getContractFactory("VersatilToken");
    versatilToken = await VersatilToken.deploy(
      token0Addr,
      token1Addr,
      routerAddr,
      poolAddr,
      "VersatilToken",
      "VVT"
    );
    await versatilToken.waitForDeployment();

    await token1.mint(user.address, ethers.parseUnits(amount.toString(), 18));
  });

  it("should return the correct balance converted via Uniswap", async function () {
    const balance = await versatilToken.balanceOf(user.address);

    const expected = ethers.parseUnits((ratio * amount).toString(), 18);
    expect(balance).to.equal(expected);
  });

  it("should allow transfer and emit event", async function () {
    const versatilAddr = await versatilToken.getAddress();

    await token1
      .connect(user)
      .approve(versatilAddr, ethers.parseUnits("10", 18));

    await expect(
      versatilToken
        .connect(user)
        .transfer(owner.address, ethers.parseUnits("10", 18))
    ).to.emit(versatilToken, "Transfer");
  });
});