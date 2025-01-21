// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;

interface IAgniCallee {
    function agniCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}
