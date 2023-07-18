// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@agniswap/core/contracts/libraries/LowGasSafeMath.sol';

import './PeripheryPayments.sol';
import '../interfaces/IPeripheryPaymentsWithFee.sol';

import '../interfaces/external/IWMNT.sol';
import '../libraries/TransferHelper.sol';

abstract contract PeripheryPaymentsWithFee is PeripheryPayments, IPeripheryPaymentsWithFee {
    using LowGasSafeMath for uint256;

    /// @inheritdoc IPeripheryPaymentsWithFee
    function unwrapWMNTWithFee(
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) public payable override {
        require(feeBips > 0 && feeBips <= 100);

        uint256 balanceWMNT = IWMNT(WMNT).balanceOf(address(this));
        require(balanceWMNT >= amountMinimum, 'Insufficient WMNT');

        if (balanceWMNT > 0) {
            IWMNT(WMNT).withdraw(balanceWMNT);
            uint256 feeAmount = balanceWMNT.mul(feeBips) / 10_000;
            if (feeAmount > 0) TransferHelper.safeTransferMNT(feeRecipient, feeAmount);
            TransferHelper.safeTransferMNT(recipient, balanceWMNT - feeAmount);
        }
    }

    /// @inheritdoc IPeripheryPaymentsWithFee
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) public payable override {
        require(feeBips > 0 && feeBips <= 100);

        uint256 balanceToken = IERC20(token).balanceOf(address(this));
        require(balanceToken >= amountMinimum, 'Insufficient token');

        if (balanceToken > 0) {
            uint256 feeAmount = balanceToken.mul(feeBips) / 10_000;
            if (feeAmount > 0) TransferHelper.safeTransfer(token, feeRecipient, feeAmount);
            TransferHelper.safeTransfer(token, recipient, balanceToken - feeAmount);
        }
    }
}
