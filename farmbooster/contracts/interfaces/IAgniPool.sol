//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAgniPool {
    function userInfo(
        address _user
    ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);

    function getPricePerFullShare() external view returns (uint256);

    function totalLockedAmount() external view returns (uint256);

    function totalShares() external view returns (uint256);

    function BOOST_WEIGHT() external view returns (uint256);

    function MAX_LOCK_DURATION() external view returns (uint256);
}