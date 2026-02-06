// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "hardhat/console.sol";

contract MockUniswapV3Pool {
    uint160 public sqrtPriceX96;
    address public token0_;
    address public token1_;
    constructor(uint160 _sqrtPriceX96, address _token0, address _token1) {
        sqrtPriceX96 = _sqrtPriceX96;
        // console.log("MockUniswapV3Pool deployed with sqrtPriceX96:", sqrtPriceX96);
        token0_ = _token0;
        token1_ = _token1;
    }
    function slot0() external view returns (
        uint160, int24, uint16, uint16, uint16, uint8, bool
    ) {
        return (sqrtPriceX96, 0, 0, 0, 0, 0, true);
    }
    function token0() external view returns (address) {
        return token0_;
    }
    function token1() external view returns (address) {
        return token1_;
    }
}
