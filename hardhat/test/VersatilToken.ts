import { expect } from "chai";
import { network } from "hardhat";
import { assert } from "node:console";

const { ethers } = await network.connect();

describe("VersatilToken", function () {
  let token0: any;
  let token1: any;
  let router: any;
  let pool: any;
  let versatilToken: any;
  let owner: any;
  let user: any;
  let ratio = 25n; // Ratio de prix entre token1 et token0 (token1 vaut 25 fois token0)
  let amount = 1000n;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();
    // Déployer deux tokens ERC20 mock
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    token0 = await MockERC20.deploy("Token0", "TK0", 18);
    assert(token0.target, "Failed to deploy token0");
    token1 = await MockERC20.deploy("Token1", "TK1", 18);
    assert(token1.target, "Failed to deploy token1");

    // Calcul du sqrtPriceX96 pour ratio = 25 * 10^18
    const ratio = 25n;
    // sqrtPriceX96 = sqrt(ratio) * 2^96
    // Utilisation de ethers.BigNumber pour éviter l'overflow
    function sqrtBigInt(value: bigint): bigint {
      // Newton's method for integer square root
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
    const sqrtRatio = sqrtBigInt(ratio);
    const sqrtPriceX96 = sqrtRatio * 2n ** 96n;
    const MockUniswapV3Pool = await ethers.getContractFactory(
      "MockUniswapV3Pool",
    );
    // Déployer un router mock
    pool = await MockUniswapV3Pool.deploy(
      sqrtPriceX96,
      token0.target,
      token1.target,
    );
    assert(pool.target, "Failed to deploy pool");
    const MockRouter = await ethers.getContractFactory("MockRouter");
    router = await MockRouter.deploy(token0.target);
    assert(router.target, "Failed to deploy router");
    // Déployer VersatilToken
    const VersatilToken = await ethers.getContractFactory("VersatilToken");
    versatilToken = await VersatilToken.deploy(
      token0.target,
      token1.target,
      router.target,
      pool.target,
      "VersatilToken",
      "VVT",
    );
    // Mint des tokens à l'utilisateur
    await token1.mint(user.address, ethers.parseUnits(amount.toString(), 18));
  });

  it("should return the correct balance converted via Uniswap", async function () {
    // Le solde converti doit être > 0 si le pool est bien paramétré
    const balance = await versatilToken.balanceOf(user.address);
    expect(balance).to.be.a("bigint");
    expect(balance).to.be.greaterThan(0n);
    expect(balance).to.equal(ethers.parseUnits((ratio * amount).toString(), 18)); // 1000 TK1 convertis en TK0 au ratio 1:25
  });

  it("should allow transfer and emit event", async function () {
    await token1
      .connect(user)
      .approve(versatilToken.target, ethers.parseUnits("10", 18));
    await expect(
      versatilToken
        .connect(user)
        .transfer(owner.address, ethers.parseUnits("10", 18)),
    ).to.emit(versatilToken, "Transfer");
  });
});
