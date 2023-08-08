// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMasterChefV3 {
    function userPositionInfos(
        uint256 _tokenId
    ) external view returns (uint128, uint128, int24, int24, uint256, uint256, address, uint256, uint256);

    function poolInfo(
        uint256 _pid
    ) external view returns (uint256, address, address, address, uint24, uint256, uint256);

    function getBoostMultiplier(address _user, uint256 _pid) external view returns (uint256);

    function updateBoostMultiplier(uint256 _tokenId, uint256 _newMultiplier) external;
}