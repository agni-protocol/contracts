// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IScoreCalculator {
    function calculate(address token, uint256 tokenIdOrAmount) external view returns (uint256 score);
}