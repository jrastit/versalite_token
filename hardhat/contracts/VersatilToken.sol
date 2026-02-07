// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./lib/FullMath.sol";



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
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

interface IUniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

contract VersatilToken is Context, IERC20, IERC20Metadata {
    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;

    address public immutable TOKEN0;
    address public immutable TOKEN1;
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
        TOKEN0 = _token0;
        TOKEN1 = _token1;
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

    // function balanceOf(address account) public view override returns (uint256) {
    //     uint256 token1Balance = IERC20(TOKEN1).balanceOf(account);
    //     if (token1Balance == 0) return 0;
    //     // Lire le prix spot EUROC/USDC depuis la pool Uniswap V3
    //     (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(UNISWAP_POOL)
    //         .slot0();
    //     // Déterminer l'ordre des tokens dans la pool
    //     address token0 = IUniswapV3Pool(UNISWAP_POOL).token0();
    //     address token1 = IUniswapV3Pool(UNISWAP_POOL).token1();
    //     uint256 sqrtP = uint256(sqrtPriceX96);
    //     require(sqrtP != 0, "sqrtPriceX96=0");

    //     uint256 Q96 = uint256(1) << 96;
    //     uint256 Q192 = uint256(1) << 192;

    //     // price1Per0_X96 = sqrtP^2 / 2^96  (safe: shift before squaring)
    //     uint256 s = sqrtP >> 48; // reduce magnitude
    //     uint256 price1Per0_X96 = s * s; // == sqrtP^2 / 2^96
    //     require(price1Per0_X96 != 0, "price1Per0_X96=0");

    //     // price0Per1_X96 = Q96^2 / price1Per0_X96 = Q192 / price1Per0_X96
    //     uint256 price0Per1_X96 = Q192 / price1Per0_X96;
    //     require(price0Per1_X96 != 0, "price0Per1_X96=0");

    //     if (token0 == TOKEN1 && token1 == TOKEN0) {
    //         // token0Amount = token1Amount * (token0 per token1)
    //         return (token1Balance * price0Per1_X96) / Q96;
    //     } else if (token0 == TOKEN0 && token1 == TOKEN1) {
    //         // token1Amount = token0Amount * (token1 per token0)
    //         return (token1Balance * price1Per0_X96) / Q96;
    //     } else {
    //         revert("Pool tokens do not match");
    //     }
    // }

    function balanceOf(address account) public view override returns (uint256) {
    uint256 amountIn = IERC20(TOKEN1).balanceOf(account);
    if (amountIn == 0) return 0;

    (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(UNISWAP_POOL).slot0();
    require(sqrtPriceX96 != 0, "sqrtPriceX96=0");

    address poolToken0 = IUniswapV3Pool(UNISWAP_POOL).token0();
    address poolToken1 = IUniswapV3Pool(UNISWAP_POOL).token1();

    // price = (sqrtPriceX96^2) / 2^192  gives token1/token0 in raw units
    uint256 priceX192 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);

    uint8 dec0 = IERC20Metadata(TOKEN0).decimals();
    uint8 dec1 = IERC20Metadata(TOKEN1).decimals();

    // We want: amountOut (TOKEN0 units) for amountIn (TOKEN1 units)
    // If pool token0 == TOKEN0 and token1 == TOKEN1:
    //   sqrtPrice encodes TOKEN1 per TOKEN0, so TOKEN0 per TOKEN1 is the inverse.
    if (poolToken0 == TOKEN0 && poolToken1 == TOKEN1) {
        // amountOut = amountIn * 2^192 / priceX192, then adjust decimals
        uint256 rawOut = FullMath.mulDiv(amountIn, (1 << 192), priceX192);

        // rawOut is in TOKEN0 base units already because amountIn is TOKEN1 base units and we inverted the raw price.
        // But because pool price is in raw units, it already accounts for decimals. So no extra 10^dec shift is needed here.
        return rawOut;

    } else if (poolToken0 == TOKEN1 && poolToken1 == TOKEN0) {
        // In this orientation, sqrtPrice encodes TOKEN0 per TOKEN1 directly.
        uint256 rawOut = FullMath.mulDiv(amountIn, priceX192, (1 << 192));
        return rawOut;
    } else {
        revert("Pool tokens do not match");
    }
}

    // Laisser la fonction transfer standard revert
    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        address sender = _msgSender();
        require(
            IERC20(TOKEN1).balanceOf(sender) >= amount,
            "Insufficient balance"
        );
        require(
            IERC20(TOKEN1).transferFrom(sender, address(this), amount),
            "transfer failed"
        );
        _swapExactOutput(recipient, amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        address owner = _msgSender();
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        // uint256 currentAllowance = _allowances[sender][_msgSender()];
        // require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        // _allowances[sender][_msgSender()] = currentAllowance - amount;
        require(
            IERC20(TOKEN1).balanceOf(sender) >= amount,
            "Insufficient balance"
        );
        require(
            IERC20(TOKEN1).transferFrom(sender, address(this), amount),
            "transfer failed"
        );
        _swapExactOutput(recipient, amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _swapExactOutput(address to, uint256 amount) internal {
        IERC20(TOKEN1).approve(UNISWAP_ROUTER, amount);
        ExactInputSingleParams memory params = ExactInputSingleParams({
            tokenIn: TOKEN1,
            tokenOut: TOKEN0,
            fee: FEE,
            recipient: to,
            deadline: block.timestamp,
            amountIn: amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        IUniswapV3Router(UNISWAP_ROUTER).exactInputSingle(params);
    }

    // Pas besoin de receive payable
}
