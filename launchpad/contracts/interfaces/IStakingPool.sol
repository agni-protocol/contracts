// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IStakingPool {
    struct StakeInfo {
        address user;
        address token;
        uint256 tokenIdOrAmount;
        uint256 unlockTime;
        uint256 score;
        bool unstaked;
        bool isERC721;
    }

    event StakingTokenAdded(address indexed token);
    event StakingTokenRemoved(address indexed token);
    event LockPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);
    event ScoreCalculatorUpdated(address indexed oldCalculator, address indexed newCalculator);
    event TierScoreUpdated(uint256 tier, uint256 oldScore, uint256 newScore);
    event Staked(
        address indexed user,
        address indexed token,
        uint256 tokenIdOrAmount,
        uint256 unlockTime,
        uint256 score,
        uint256 tier,
        uint256 stakeId
    );
    event Unstaked(address indexed user, uint256 stakeId,uint256 tokenIdOrAmount, uint256 score, uint256 tier);

    function WMNT() external view returns (address);
    function scoreCalculator() external view returns (address);
    function lockPeriod() external view returns (uint256);
    function isStakingToken(address token) external view returns (bool);
    function getScoreByTier(uint256 tier) external view returns (uint256 score);
    function getTierByScore(uint256 score) external view returns (uint256 tier);
    function getStakeInfo(uint256 stakeId) external view returns (StakeInfo memory);
    function getUserTier(address user) external view returns (uint256 tier);
    function getUserScore(address user) external view returns (uint256 score);

    function addStakingToken(address token) external;
    function removeStakingToken(address token) external;
    function updateLockPeriod(uint256 newPeriod) external;
    function updateScoreCalculator(address newCalculator) external;
    function setTierScore(uint256 tier, uint256 score) external;
    function stake(address token, uint256 tokenIdOrAmount) external returns (uint256 stakeId);
    function stakeNativeToken() external payable returns (uint256 stakeId);
    function unstake(uint256[] calldata stakeIds) external;
}