import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.connect();

function sqrtBigInt(value: bigint): bigint {
  if (value < 0n) throw new Error("sqrt of negative");
  if (value < 2n) return value;

  // Newton-Raphson
  let x0 = value;
  let x1 = (x0 + 1n) >> 1n;
  while (x1 < x0) {
    x0 = x1;
    x1 = (x1 + value / x1) >> 1n;
  }
  return x0;
}

describe("vvUSDC_stETH (mocked Uniswap)", function () {
  let vvUSDC_stETH: any;
  let mockRouter: any;
  let mockPool: any;
  let usdc: any;
  let steth: any;
  let owner: any;
  let user: any;

   beforeEach(async function () {
  [owner, user] = await ethers.getSigners();

  const ownerAddr = await owner.getAddress();
  const userAddr = await user.getAddress();

  // Deploy mock USDC and stETH
  const MockERC20 = await ethers.getContractFactory("MockERC20");

  usdc = await MockERC20.deploy("USD Coin", "USDC", 6);
  await usdc.waitForDeployment();

  steth = await MockERC20.deploy("staked Ether", "stETH", 18);
  await steth.waitForDeployment();

  const usdcAddr = await usdc.getAddress();
  const stethAddr = await steth.getAddress();
  if (!usdcAddr || usdcAddr === "0x0000000000000000000000000000000000000000") throw new Error("usdcAddr is invalid");
  if (!stethAddr || stethAddr === "0x0000000000000000000000000000000000000000") throw new Error("stethAddr is invalid");

  // Mint stETH to user
  await steth.mint(userAddr, ethers.parseEther("10"));

  // Deploy mocks
  const Router = await ethers.getContractFactory("MockRouter");
  mockRouter = await Router.deploy(usdcAddr);
  await mockRouter.waitForDeployment();
  const routerAddr = await mockRouter.getAddress();
  if (!routerAddr || routerAddr === "0x0000000000000000000000000000000000000000") throw new Error("routerAddr is invalid");

  /**
   * sqrtPriceX96 for 1 stETH = 2000 USDC
   * Uniswap v3: price = token1/token0 in Q64.96 via sqrtPriceX96
   *
   * If your pool is (token0=stETH 18dec, token1=USDC 6dec):
   * price(token1/token0) = 2000 * 10^6 / 10^18 = 2000e6 / 1e18
   *
   * sqrtPriceX96 = floor( sqrt(price) * 2^96 )
   *
   * We'll compute using bigint:
   * sqrtPriceX96 = floor( sqrt( (2000 * 10^6 * 2^192) / 10^18 ) )
   */
  const Q192 = 2n ** 192n;
  const numerator = 2000n * 10n ** 6n * Q192;
  const denominator = 10n ** 18n;
  const ratioX192 = numerator / denominator;

  const sqrtPriceX96 = sqrtBigInt(ratioX192); // bigint

  const MockPool = await ethers.getContractFactory("MockUniswapV3Pool");
  // Utilise des adresses valides pour tous les paramètres
  const token0 = stethAddr;
  const token1 = usdcAddr;
  mockPool = await MockPool.deploy(sqrtPriceX96, token0, token1);
  await mockPool.waitForDeployment();
  const poolAddr = await mockPool.getAddress();
  if (!poolAddr || poolAddr === "0x0000000000000000000000000000000000000000") throw new Error("poolAddr is invalid");

  // Deploy vvUSDC_stETH
  const Contract = await ethers.getContractFactory("vvUSDC_stETH");
  vvUSDC_stETH = await Contract.deploy(
    usdcAddr,
    stethAddr,
    routerAddr,
    poolAddr
  );
  await vvUSDC_stETH.waitForDeployment();
});


  it("should return correct USDC value in balanceOf (spot price)", async function () {
    // 1 stETH = 2000 USDC
    const stethAmount = ethers.parseEther("1");
    const vvAddr = await vvUSDC_stETH.getAddress();
    expect(vvAddr).to.be.a("string").and.satisfy((a: string) => a !== "0x0000000000000000000000000000000000000000" && a !== null && a !== undefined);
    await steth.connect(user).approve(vvAddr, stethAmount);
    // balanceOf doit retourner environ 2000 USDC (6 décimales)
    const stethBal = await steth.balanceOf(user.address);
    console.log("stethBalance user:", stethBal.toString());
    // Diagnostic : afficher les adresses stETH et USDC
    const stethAddr = await steth.getAddress();
    const usdcAddr = await usdc.getAddress();
    console.log("stethAddr:", stethAddr);
    console.log("usdcAddr:", usdcAddr);
    // Diagnostic : lire slot0 et l’ordre des tokens dans la pool
    const slot0 = await mockPool.slot0();
    const poolToken0 = await mockPool.token0();
    const poolToken1 = await mockPool.token1();
    console.log("slot0.sqrtPriceX96:", slot0[0].toString());
    console.log("poolToken0:", poolToken0);
    console.log("poolToken1:", poolToken1);
    // Calcul JS du prix spot pour vérifier la formule Solidity
    const sqrtPriceX96 = BigInt(slot0[0].toString());
    const priceX96 = sqrtPriceX96 * sqrtPriceX96 / (2n ** 192n);
    const expectedUSDC = stethBal * priceX96 / (10n ** 18n);
    console.log("[JS] priceX96:", priceX96.toString());
    console.log("[JS] expectedUSDC:", expectedUSDC.toString());
    const usdcValue = await vvUSDC_stETH.balanceOf(user.address);
    console.log("usdcValue:", usdcValue.toString());
    expect(usdcValue).to.be.closeTo(2000000000n, 1000000n);
  });

  it("should transferWithStETH and emit event (mocked)", async function () {
    const amountUSDC = 2000000000n; // 2000 USDC
    const vvAddr = await vvUSDC_stETH.getAddress();
    expect(vvAddr).to.be.a("string").and.satisfy((a: string) => a !== "0x0000000000000000000000000000000000000000" && a !== null && a !== undefined);
    // Approve stETH to contract
    await steth.connect(user).approve(vvAddr, ethers.parseEther("1"));
    // Call transferWithStETH
    await expect(
      vvUSDC_stETH.connect(user).transferWithStETH(owner.address, amountUSDC)
    ).to.emit(vvUSDC_stETH, "Transfer").withArgs(user.address, owner.address, amountUSDC);
  });
});
