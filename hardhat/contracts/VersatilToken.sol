// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

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
interface IUniswapV3Router {
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

interface IUniswapV3Pool {
    function slot0() external view returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked);
    function token0() external view returns (address);
    function token1() external view returns (address);

}


contract VersatilToken is Context, IERC20, IERC20Metadata {
    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;

    address public immutable USDC;
    address public immutable EUROC;
    address public immutable UNISWAP_ROUTER;
    address public immutable UNISWAP_POOL;
    uint24 public constant FEE = 3000; // 0.3%

    mapping(address => mapping(address => uint256)) private _allowances;


    constructor(
        address _token0,
        address _token1,
        address _router,
        address _pool,
        string memory name_,
        string memory symbol_
    ) {
        USDC = _token0;
        EUROC = _token1;
        UNISWAP_ROUTER = _router;
        UNISWAP_POOL = _pool;
        _name = name_;
        _symbol = symbol_;
    }


    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return 0; // Not relevant, as supply is dynamic
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 eurocBalance = IERC20(EUROC).balanceOf(account);
        if (eurocBalance == 0) return 0;
        // Lire le prix spot EUROC/USDC depuis la pool Uniswap V3
        (uint160 sqrtPriceX96,, , , , ,) = IUniswapV3Pool(UNISWAP_POOL).slot0();
        // Déterminer l'ordre des tokens dans la pool
        address token0 = IUniswapV3Pool(UNISWAP_POOL).token0();
        address token1 = IUniswapV3Pool(UNISWAP_POOL).token1();
        uint256 priceX96;
        if (token0 == EUROC && token1 == USDC) {
            // prix = (sqrtPriceX96^2) / 2^192
            priceX96 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96) / (2**192);
            // EUROC -> USDC
            // Adapter les décimales : USDC 6, EUROC 6 ou 18
            return eurocBalance * priceX96 / (10**18);
        } else if (token0 == USDC && token1 == EUROC) {
            // prix = (2^192) / (sqrtPriceX96^2)
            priceX96 = (2**192) / (uint256(sqrtPriceX96) * uint256(sqrtPriceX96));
            // EUROC -> USDC
            return eurocBalance * priceX96 / (10**18);
        } else {
            return 0;
        }
    }

    // Nouvelle fonction payable pour swap stETH contre USDC
    // Nouvelle fonction : swap tout le solde stETH de l'utilisateur contre USDC (exemple, à adapter selon besoin)
    function transferWithStETH(address recipient, uint256 stethAmount) public returns (bool) {
        address sender = _msgSender();
        require(IERC20(EUROC).balanceOf(sender) >= stethAmount, "Insufficient stETH");
        require(IERC20(EUROC).transferFrom(sender, address(this), stethAmount), "stETH transfer failed");
        _swapExactOutputUSDC(recipient, stethAmount);
        emit Transfer(sender, recipient, stethAmount);
        return true;
    }

    // Laisser la fonction transfer standard revert
    function transfer(address, uint256) public pure override returns (bool) {
        revert("Use transferWithStETH");
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 stethAmount) public override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= stethAmount, "ERC20: transfer amount exceeds allowance");
        _allowances[sender][_msgSender()] = currentAllowance - stethAmount;
        require(IERC20(EUROC).balanceOf(sender) >= stethAmount, "Insufficient stETH");
        require(IERC20(EUROC).transferFrom(sender, address(this), stethAmount), "stETH transfer failed");
        _swapExactOutputUSDC(recipient, stethAmount);
        emit Transfer(sender, recipient, stethAmount);
        return true;
    }

    function _swapExactOutputUSDC(address to, uint256 stethAmount) internal {
        // Swap tout le stETH reçu contre USDC (slippage à gérer côté front ou à améliorer ici)
        IERC20(EUROC).approve(UNISWAP_ROUTER, stethAmount);
        ExactInputSingleParams memory params = ExactInputSingleParams({
            tokenIn: EUROC,
            tokenOut: USDC,
            fee: FEE,
            recipient: to,
            deadline: block.timestamp,
            amountIn: stethAmount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        IUniswapV3Router(UNISWAP_ROUTER).exactInputSingle(params);
    }


    // Pas besoin de receive payable
}
