// Sources flattened with hardhat v2.28.4 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.4.16;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


// File @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity >=0.6.2;

/**
 * @dev Interface for the optional metadata functions from the ERC-20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/utils/Context.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}


// File contracts/lib/FullMath.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;

// Full precision multiplication/division (Uniswap-style), adapted for Solidity 0.8.x
library FullMath {
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            uint256 prod0;
            uint256 prod1;
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            if (prod1 == 0) {
                require(denominator > 0);
                return prod0 / denominator;
            }

            require(denominator > prod1);

            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            uint256 twos = denominator & (~denominator + 1);
            assembly {
                denominator := div(denominator, twos)
                prod0 := div(prod0, twos)
                twos := add(div(sub(0, twos), twos), 1)
            }

            prod0 |= prod1 * twos;

            uint256 inv = (3 * denominator) ^ 2;
            inv *= 2 - denominator * inv;
            inv *= 2 - denominator * inv;
            inv *= 2 - denominator * inv;
            inv *= 2 - denominator * inv;
            inv *= 2 - denominator * inv;
            inv *= 2 - denominator * inv;

            result = prod0 * inv;
            return result;
        }
    }
}


// File contracts/VersatilToken.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;




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
        return IERC20Metadata(TOKEN0).decimals();
    }

    function totalSupply() public view override returns (uint256) {
        return IERC20(TOKEN0).totalSupply();
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
