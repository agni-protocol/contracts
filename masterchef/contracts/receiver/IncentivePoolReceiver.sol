// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IIncentivePool.sol";

contract IncentivePoolReceiver is Ownable2Step {
    using SafeERC20 for IERC20;

    IERC20 public immutable incentiveToken;
    IIncentivePool public immutable incentivePool;

    address public operatorAddress;

    error NotOwnerOrOperator();
    error ZeroAddress();
    error NoBalance();

    event NewOperator(address indexed operatorAddress);
    event Upkeep(address indexed to, uint256 amount);
    event Withdraw(address indexed token, address indexed to, uint256 amount);

    modifier onlyOwnerOrOperator() {
        if (msg.sender != operatorAddress && msg.sender != owner()) revert NotOwnerOrOperator();
        _;
    }

    /// @notice Constructor.
    /// @param _incentivePool IncentivePool address.
    /// @param _incentiveToken incentiveToken token address.
    constructor(IIncentivePool _incentivePool, IERC20 _incentiveToken) {
        incentivePool = _incentivePool;
        incentiveToken = _incentiveToken;

        incentiveToken.safeApprove(address(_incentivePool), type(uint256).max);
    }

    /// @notice upkeep.
    /// @dev Callable by owner or operator.
    /// @param _amount Injection amount, the injection amount can be flexibly controlled.
    /// @param _duration The period duration.
    function upkeep(uint256 _amount, uint256 _duration) external onlyOwnerOrOperator {
        uint256 amount = _amount;
        uint256 balance = incentiveToken.balanceOf(address(this));
        if (_amount == 0 || _amount > balance) {
            amount = balance;
        }
        incentivePool.upkeep(amount, _duration);
        emit Upkeep(address(incentivePool), amount);
    }

    /// @notice Set operator address.
    /// @dev Callable by owner.
    /// @param _operatorAddress New operator address.
    function setOperator(address _operatorAddress) external onlyOwner {
        if (_operatorAddress == address(0)) revert ZeroAddress();
        operatorAddress = _operatorAddress;
        emit NewOperator(_operatorAddress);
    }

    /// @notice Withdraw unexpected tokens sent to the receiver, can also withdraw agni.
    /// @dev Callable by owner.
    /// @param _token Token address.
    function withdraw(IERC20 _token) external onlyOwner {
        uint256 amount = _token.balanceOf(address(this));
        _token.safeTransfer(msg.sender, amount);
        emit Withdraw(address(_token), msg.sender, amount);
    }
}