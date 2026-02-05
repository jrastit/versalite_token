// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockQuoter {
    uint256 public ethToUsdcRate; // e.g. 1 ETH = 2000 USDC (with 6 decimals)
    constructor(uint256 _rate) { ethToUsdcRate = _rate; }
    function quoteExactInputSingle(address, address, uint24, uint256 amountIn, uint160) external view returns (uint256) {
        return (amountIn * ethToUsdcRate) / 1e18;
    }
}

struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
}

contract MockRouter {
    address public usdc;
    constructor(address _usdc) { usdc = _usdc; }
    event Swapped(address indexed to, uint256 ethIn, uint256 usdcOut);
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut) {
        emit Swapped(params.recipient, msg.value, params.amountOutMinimum);
        return params.amountOutMinimum;
    }
}
