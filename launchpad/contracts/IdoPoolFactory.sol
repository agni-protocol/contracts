// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./interfaces/IIdoPoolFactory.sol";
import "./interfaces/IIdoPool.sol";
import "./interfaces/IInsurancePool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract IdoPoolFactory is IIdoPoolFactory, Ownable {
    address public override platformTreasury;
    address public override insurancePool;
    address public override idoPoolTemplate;
    address public override keeper;
    address public override stakingPool;

    uint8 public override platformCommissionFeeRate;
    uint8 public override insuranceFeeRate;
    mapping(address => bool) public override isRaisingToken;
    mapping(address => address) public override getIdoPool;

    modifier onlyKeeper() {
        require(msg.sender == keeper, "only keeper");
        _;
    }

    constructor(address idoPoolTemplate_) {
        idoPoolTemplate = idoPoolTemplate_;
    }

    function setInsurancePool(address insurancePool_, uint8 insuranceFeeRate_) external override onlyOwner {
        require(insurancePool_ != address(0), "zero address");
        require(insuranceFeeRate_ < 100, "need lesss that 100");
        insurancePool = insurancePool_;
        insuranceFeeRate = insuranceFeeRate_;
    }


    function updateStakingPool(address newStakingPool) external override onlyOwner {
        require(newStakingPool != address(0), "zero address");
        emit StakingPoolUpdated(keeper, newStakingPool);
        stakingPool = newStakingPool;
    }

    function addRaisingToken(address token) external override onlyOwner {
        require(token != address(0), "zero address");
        require(!isRaisingToken[token], "already added");
        isRaisingToken[token] = true;
        emit RaisingTokenAdded(token);
    }

    function removeRaisingToken(address token) external override onlyOwner {
        require(isRaisingToken[token], "token not found");
        isRaisingToken[token] = false;
        emit RaisingTokenRemoved(token);
    }

    function updateInsuranceFeeRate(uint8 newRate) external override onlyOwner {
        require(insurancePool != address(0), "insurancePool not set");
        require(newRate < 100, "need lesss that 100");
        emit InsuranceFeeRateUpdated(insuranceFeeRate, newRate);
        insuranceFeeRate = newRate;
    }

    function updatePlatformCommissionFeeRate(uint8 newRate) external override onlyOwner {
        require(platformTreasury != address(0), "platformTreasury not set");
        require(newRate < 100, "need lesss that 100");
        emit PlatformCommissionFeeRateUpdated(platformCommissionFeeRate, newRate);
        platformCommissionFeeRate = newRate;
    }

    function updateIdoPoolTemplate(address newTemplate) external override onlyOwner {
        require(newTemplate != address(0), "zero address");
        emit IdoPoolTemplateUpdated(idoPoolTemplate, newTemplate);
        idoPoolTemplate = newTemplate;
    }

    function updateKeeper(address newKeeper) external override onlyOwner {
        require(newKeeper != address(0), "zero address");
        emit KeeperUpdated(keeper, newKeeper);
        keeper = newKeeper;
    }


    function updatePlatformTreasury(address newTreasury) external override onlyOwner {
        require(newTreasury != address(0), "zero address");
        emit PlatformTreasuryUpdated(platformTreasury, newTreasury);
        platformTreasury = newTreasury;
    }
    
    function createIdoPool(Parameters calldata parameters) external override onlyKeeper returns (address pool) {
        require(parameters.fundraiser != address(0), "fundraiser is zero address");
        require(parameters.sellingToken != address(0), "sellingToken is zero address");
        require(isRaisingToken[parameters.raisingToken], "unsupport raisingToken");
        require(parameters.presaleAndEnrollStartTime > block.timestamp, "presaleAndEnrollStartTime < currentTime");
        require(
            parameters.publicSaleDepositStartTime > parameters.presaleAndEnrollStartTime + parameters.presaleAndEnrollPeriod, 
            "wrong public sale start deposit time");
        require(parameters.tgeUnlockRatio <= 100, "tgeUnlockRatio over 100");

        bytes32 salt = keccak256(abi.encodePacked(blockhash(block.number), block.timestamp));
        pool = Clones.cloneDeterministic(idoPoolTemplate,salt);
        IIdoPool(pool).initialize(
            address(this), 
            insurancePool, 
            stakingPool,
            platformTreasury,
            parameters.fundraiser,
            parameters.raisingToken, 
            parameters.sellingToken, 
            insuranceFeeRate,
            platformCommissionFeeRate
        );
        IIdoPool(pool).initParams(
            parameters.totalSupply, 
            parameters.presalePrice,
            parameters.publicSalePrice,
            parameters.presaleAndEnrollStartTime,
            parameters.presaleAndEnrollPeriod,
            parameters.publicSaleDepositStartTime,
            parameters.publicSaleDepositPeriod,
            parameters.claimStartTime,
            parameters.lockPeriod,
            parameters.tgeUnlockRatio
        );
        getIdoPool[parameters.sellingToken] = pool;

        if (insurancePool != address(0)) {
            IInsurancePool(insurancePool).registerIdoPool(pool);
        }

        emit IdoPoolCreated(
            pool,
            parameters,
            insuranceFeeRate,
            platformCommissionFeeRate
        );
    }
}