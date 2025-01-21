// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.6;


import "./interfaces/IAgniRouterV2.sol";
import "./interfaces/IAgniFactory.sol";
import "./libraries/AgniLibrary.sol";
import "./libraries/SafeMath.sol";
import "./libraries/SafeTransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AgniRouterV2 is IAgniRouterV2 {
    using SafeMath for uint256;

    address public immutable override factoryV2;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "AgniRouter: EXPIRED");
        _;
    }

    constructor(address _factory) public {
        factoryV2 = _factory;
    }


    // supports fee-on-transfer tokens
    // requires the initial amount to have already been sent to the first pair
    // `refundETH` should be called at very end of all swaps
    function _swap(address[] memory path, address _to) private {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = AgniLibrary.sortTokens(input, output);
            IAgniPair pair = IAgniPair(AgniLibrary.pairFor(factory, input, output));
            uint256 amountInput;
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) =
                    input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = AgniLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
            address to = i < path.length - 2 ? AgniLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    /// @inheritdoc IV2SwapRouter
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable override nonReentrant returns (uint256 amountOut) {
        IERC20 srcToken = IERC20(path[0]);
        IERC20 dstToken = IERC20(path[path.length - 1]);

        // use amountIn == Constants.CONTRACT_BALANCE as a flag to swap the entire balance of the contract
        bool hasAlreadyPaid;
        if (amountIn == Constants.CONTRACT_BALANCE) {
            hasAlreadyPaid = true;
            amountIn = srcToken.balanceOf(address(this));
        }

        pay(
            address(srcToken),
            hasAlreadyPaid ? address(this) : msg.sender,
            SmartRouterHelper.pairFor(factoryV2, address(srcToken), path[1]),
            amountIn
        );

        // find and replace to addresses
        if (to == Constants.MSG_SENDER) to = msg.sender;
        else if (to == Constants.ADDRESS_THIS) to = address(this);

        uint256 balanceBefore = dstToken.balanceOf(to);

        _swap(path, to);

        amountOut = dstToken.balanceOf(to).sub(balanceBefore);
        require(amountOut >= amountOutMin);
    }

    /// @inheritdoc IV2SwapRouter
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external payable override nonReentrant returns (uint256 amountIn) {
        address srcToken = path[0];

        amountIn = SmartRouterHelper.getAmountsIn(factoryV2, amountOut, path)[0];
        require(amountIn <= amountInMax);

        pay(srcToken, msg.sender, SmartRouterHelper.pairFor(factoryV2, srcToken, path[1]), amountIn);

        // find and replace to addresses
        if (to == Constants.MSG_SENDER) to = msg.sender;
        else if (to == Constants.ADDRESS_THIS) to = address(this);

        _swap(path, to);
    }


    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = AgniLibrary.sortTokens(input, output);
            IAgniPair pair = IAgniPair(AgniLibrary.pairFor(factoryV2, input, output));
            uint256 amountInput;
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) =
                    input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = AgniLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
            address to = i < path.length - 2 ? AgniLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external virtual override  returns (uint256 amountOut) {
        SafeTransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            AgniLibrary.pairFor(factory, path[0], path[1]),
            amountIn
        );
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swap(path, to);
        amountOut =  IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore);
        require(
            amountOut >= amountOutMin,
            "AgniRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external virtual override  returns (uint256[] memory amounts) {
        amounts = AgniLibrary.getAmountsIn(factoryV2, amountOut, path);
        require(amounts[0] <= amountInMax, "AgniRouter: EXCESSIVE_INPUT_AMOUNT");
        SafeTransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            AgniLibrary.pairFor(factoryV2, path[0], path[1]),
            amounts[0]
        );
        _swap(path, to);
    }

}
