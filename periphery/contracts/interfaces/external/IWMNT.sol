// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WMNT
interface IWMNT is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;

    function totalSupply() override external view returns (uint);

    function approve(address guy, uint wad) override external returns (bool);

    function transfer(address dst, uint wad) override external returns (bool);

    function transferFrom(address src, address dst, uint wad) override external returns (bool);
}