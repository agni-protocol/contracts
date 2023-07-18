// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IIdoPoolFactory {
    event RaisingTokenAdded(address indexed token);
    event RaisingTokenRemoved(address indexed token);
    event InsuranceFeeRateUpdated(uint8 oldRate, uint8 newRate);
    event PlatformCommissionFeeRateUpdated(uint8 oldRate, uint8 newRate);
    event IdoPoolTemplateUpdated(address indexed oldTemplate, address indexed newTemplate);
    event KeeperUpdated(address indexed oldKeeper, address indexed newKeeper);
    event StakingPoolUpdated(address indexed oldStakingPool, address indexed newStakingPool);
    event PlatformTreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event IdoPoolCreated(address indexed poolAddress, Parameters params, uint8 insuranceFeeRate,uint8 platformCommissionFeeRate);

    struct Parameters {
        address fundraiser;
        address raisingToken;
        address sellingToken;
        uint256 totalSupply;
        uint256 presalePrice;
        uint256 publicSalePrice;
        uint256 presaleAndEnrollStartTime;
        uint256 presaleAndEnrollPeriod;
        uint256 publicSaleDepositStartTime;
        uint256 publicSaleDepositPeriod;
        uint256 claimStartTime;
        uint256 lockPeriod;
        uint8 tgeUnlockRatio;
    }
    
    function platformTreasury() external view returns (address);
    function insurancePool() external view returns (address);
    function idoPoolTemplate() external view returns (address);
    function keeper() external view returns (address);
    function stakingPool() external view returns (address);
    function platformCommissionFeeRate() external view returns (uint8);
    function insuranceFeeRate() external view returns (uint8);
    function isRaisingToken(address token) external view returns (bool);
    function getIdoPool(address sellingToken) external view returns (address pool);

    function setInsurancePool(address insurancePool_, uint8 insuranceFeeRate_) external;
    function addRaisingToken(address token) external;
    function removeRaisingToken(address token) external;
    function updateInsuranceFeeRate(uint8 newRate) external;
    function updatePlatformCommissionFeeRate(uint8 newRate) external;
    function updateIdoPoolTemplate(address newTemplate) external;
    function updateKeeper(address newKeeper) external;
    function updateStakingPool(address newStakingPool) external;
    function updatePlatformTreasury(address newTreasury) external;
    
    function createIdoPool(Parameters calldata parameters) external returns (address pool);
}