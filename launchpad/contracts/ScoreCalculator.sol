// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./interfaces/IScoreCalculator.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@agniswap/core/contracts/interfaces/IAgniPool.sol";
import "@agniswap/core/contracts/libraries/TickMath.sol";
import "@agniswap/periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@agniswap/periphery/contracts/libraries/PositionValue.sol";
import "@agniswap/periphery/contracts/libraries/PoolAddress.sol";

contract ScoreCalculator is IScoreCalculator, Initializable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PoolSupported(address tokenA, address tokenB, uint24 fee);
    event TokenPriceSet(address token, uint256 price);

    address public owner;
    address public positionManager;
    address public deployer;
    address public agniToken;
    address public veToken;

    mapping(address => uint256) public tokenPrice;

    mapping(address => bool) private _poolSupported;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function initialize(address positionManager_) external initializer {
        owner = msg.sender;
        positionManager = positionManager_;
        deployer = INonfungiblePositionManager(positionManager).deployer();
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function isPoolSupported(address tokenA, address tokenB, uint24 fee) external view returns (bool) {
        PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(tokenA, tokenB, fee);
        address pool = PoolAddress.computeAddress(deployer, poolKey);
        return _poolSupported[pool];
    }

   // price is the price of token-USD, and the precision needs to be expanded to 8 digits. 
   // If the actual price is 0.2, then price = 0.2 * 10^8 = 20000000
    function setTokenPrice(address token, uint256 price) external onlyOwner {
        require(token != address(0), "zero address");
        require(price > 0, "zero price");
        tokenPrice[token] = price;
    }

    function supportPool(address tokenA, address tokenB, uint24 fee) external onlyOwner returns (address pool) {
        PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(tokenA, tokenB, fee);
        pool = PoolAddress.computeAddress(deployer, poolKey);
        require(pool != address(0), "pool is zero address");
        require(!_poolSupported[pool], "already supported");
        _poolSupported[pool] = true;
        emit PoolSupported(tokenA, tokenB, fee);
    }

    function setAgniToken(address agniToken_) external onlyOwner {
        require(agniToken_ != address(0), "zero address");
        agniToken = agniToken_;
    }

    function setVeToken(address veToken_) external onlyOwner {
        require(veToken_ != address(0), "zero address");
        veToken = veToken_;
    }

    // To extend the precision of the score to 8 decimal places, you can multiply the actual score by 100000000.
    // This means that when the actual score is 1, the score value would be 100000000.
    function calculate(address token, uint256 tokenIdOrAmount) external view override returns (uint256 score) {
        if (token == positionManager) score = _calculatePosition(tokenIdOrAmount);
        if (token == agniToken) score = _calculateAgniToken(tokenIdOrAmount);
        if (token == veToken) score = _calculateVeToken(tokenIdOrAmount);
    }

    function _calculatePosition(uint256 tokenId) internal view returns (uint256 score) {
        INonfungiblePositionManager manager = INonfungiblePositionManager(positionManager);
        (
            ,
            ,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            ,
            ,
            ,
            ,
            
        ) = manager.positions(tokenId);

        address pool;
        {
            PoolAddress.PoolKey memory poolKey = PoolAddress.PoolKey(token0, token1, fee);
            pool = PoolAddress.computeAddress(deployer, poolKey);
            require(_poolSupported[pool], "unsupported pool");
        }

        uint160 sqrtPriceX96;
        uint256 ratio;
        {
            (sqrtPriceX96, , , , , , ) = IAgniPool(pool).slot0();
            // The price range for calculating fractions
            uint160 sqrtPriceX96Lower = sqrtPriceX96 * 90 / 100;
            uint160 sqrtPriceX96Upper = sqrtPriceX96 * 110 / 100;

            // The price range for liquidity
            uint160 positionSqrtPriceX96Lower = TickMath.getSqrtRatioAtTick(tickLower);
            uint160 positionSqrtPriceX96Upper = TickMath.getSqrtRatioAtTick(tickUpper);

            // To calculate the percentage of the effective range within the liquidity price range:
            if (positionSqrtPriceX96Lower == positionSqrtPriceX96Upper) {
                if (positionSqrtPriceX96Lower >= sqrtPriceX96Lower && 
                    positionSqrtPriceX96Lower <= sqrtPriceX96Upper) {
                    ratio = 100;
                }
            } else {
                if (positionSqrtPriceX96Upper > sqrtPriceX96Lower && 
                    positionSqrtPriceX96Lower < sqrtPriceX96Upper) {
                    uint256 rangeLower = (positionSqrtPriceX96Lower > sqrtPriceX96Lower) ? positionSqrtPriceX96Lower : sqrtPriceX96Lower;
                    uint256 rangeUpper = (positionSqrtPriceX96Upper < sqrtPriceX96Upper) ? positionSqrtPriceX96Upper : sqrtPriceX96Upper;
                    uint256 validDelta = rangeUpper - rangeLower;
                    uint256 positionDelta = positionSqrtPriceX96Upper - positionSqrtPriceX96Lower;
                    ratio = validDelta * 100 / positionDelta;
                }
            }
        }

        (uint256 amount0, uint256 amount1) = PositionValue.total(manager, tokenId, sqrtPriceX96);
        score = (amount0 * tokenPrice[token0] + amount1 * tokenPrice[token1]) * ratio / 100;
    }

    function _calculateAgniToken(uint256 amount) internal pure returns (uint256 score) {
    //    AgniToken has a precision of 18, while "score" has a decimals of 8. Therefore, it needs to be divided by 10^(18-8).
        score = amount / 10**10;
    }

    function _calculateVeToken(uint256 tokenId) internal view returns (uint256 score) {}
}