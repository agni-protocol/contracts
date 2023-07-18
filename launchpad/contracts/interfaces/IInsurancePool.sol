// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IInsurancePool {
    struct IdoPoolInfo {
        address paymentToken;
        uint256 presalePrice;
        uint256 publicSalePrice;
        uint256 avgPrice;
        uint256 presaleTotalQuota;
        uint256 publicSaleTotalQuota;
        uint256 needToPay;
        uint256 sellingTokenExp;
    }

    struct InsuranceDetail {
        address idoPool;
        address token;
        address user;
        uint256 buyQuota;
        uint256 price;
        bool lossClaimed;
    }

    event IdoPoolRegistered(address indexed idoPool);
    event Insured(
        address indexed idoPool, 
        address indexed token, 
        address indexed user, 
        uint256 buyQuota, 
        uint256 price, 
        uint256 insuranceId
    );
    event LossClaimed(
        address indexed operator, 
        address indexed user, 
        address indexed token, 
        uint256 insuranceId, 
        uint256 payAmount
    );

    function factory() external view returns (address);
    function isRegisteredPool(address pool) external view returns (bool);
    function getInsuranceDetail(uint256 insuranceId) external view returns (InsuranceDetail memory);
    function getInsuranceIdsByUser(address user) external view returns (uint256[] memory);
    function getIdoPoolInfo(address pool) external view returns (IdoPoolInfo memory);
    function totalNeedToPayByToken(address token) external view returns (uint256);

    function registerIdoPool(address idoPool) external;
    function insure(address user, uint256 buyQuota, uint256 price, bool isPresale) external returns (uint256 insuranceId);
    function setAvgPrice(address pool, uint256 price) external;
    function claimLoss(uint256 insuranceId) external;
}