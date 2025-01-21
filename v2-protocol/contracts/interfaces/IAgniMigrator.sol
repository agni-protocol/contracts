// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;

interface IAgniMigrator {
    function migrate(
        address token,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external;
}
