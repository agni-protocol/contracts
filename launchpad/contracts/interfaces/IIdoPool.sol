// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IIdoPool {
    struct UserIDO {
        uint256 totalPurchased; // Total purchased amount (project tokens)
        uint256 tgeUnlocked; // TGE unlocked amount, i.e., the number of tokens that are not locked after reaching the redemption period.
        uint256 refundable; // Refundable amount (fundraising tokens)
        uint256 claimed; // Claimed amount of tokens
        uint256[] insuranceIds; // List of insurance policy IDs invested in
    }

    event PresaleWhiteListSet(address[] users, uint256[] quotas);
    event PublicSaleListSet(address[] users, uint256[] quotas);
    event UserEnrolled(address user);
    event PresaleDeposited(address indexed user, uint256 buyQuota, bool buyInsurance);
    event PublicSaleDeposited(address indexed user, uint256 buyQuota, uint256 extraDeposit, bool buyInsurance);
    event CallbackFromInsurance(uint256 transferAmount);
    event Claimed(address indexed user, uint256 claimedAmount, uint256 refund);

    function factory() external view returns (address); // Returns the address of the ido factory.
    function stakingPool() external view returns (address);  // Returns the address of the staking pool.
    function raisingToken() external view returns (address); // Returns the address of the fundraising token.
    function sellingToken() external view returns (address); // Returns the address of the token being sold.
    function insurancePool() external view returns (address); // Returns the address of the insurance pool.
    function fundraiser() external view returns (address); // Returns the address of the fundraiser.
    function platformTreasury() external view returns (address); // Returns the address of the platform treasury, used for collecting fees.
    function platformCommissionFeeRate() external view returns (uint8); // Returns the platform commission fee rate as a percentage.

    function totalSupply() external view returns (uint256); // Returns the total supply of tokens for sale.
    function totalLeftQuotas() external view returns (uint256); // Returns the total remaining quota available for distribution.
    function totalBuyedByUsers() external view returns (uint256); // Returns the total amount of tokens purchased by users.
    function totalLockByInsurance() external view returns (uint256); // Returns the total amount locked due to purchasing insurance.
    function deductedByInsurance() external view returns (uint256); // Return to deducted amount by insurance.
    function totalExtraDeposit() external view returns (uint256); // Returns the total extra deposit.
    function totalRaised() external view returns (uint256); // Returns the total amount raised.

    function presalePrice() external view returns (uint256);  // Returns the presale price.
    function publicSalePrice() external view returns (uint256);  // Returns the public price.
    function presaleAndEnrollStartTime() external view returns (uint256); // Returns the start time for presale subscription and registration.
    function presaleAndEnrollEndTime() external view returns (uint256); // Returns the end time for presale subscription and registration.
    function publicSaleDepositStartTime() external view returns (uint256); // Returns the start time for public sale deposit.
    function publicSaleDepositEndTime() external view returns (uint256); // Returns the end time for public sale deposit.
    function claimStartTime() external view returns (uint256); // Returns the start time for token redemption.
    function insuranceFeeRate() external view returns (uint8); // Returns the insurance fee rate as a percentage.
    function tgeUnlockRatio() external view returns (uint8); // Returns the TGE unlock ratio as a percentage.
    function unlockTillTime() external view returns (uint256); // Returns the expiration time for locked tokens.
    function minBuyQuota() external view returns (uint256); // Returns the minQuota to buy.

    function getPresaleQuota(address user) external view returns (uint256);
    function getPublicSaleQuota(address user) external view returns (uint256);
    function isEnrolled(address user) external view returns (bool);
    function presaleDeposited(address user) external view returns (bool);
    function publicSaleDeposited(address user) external view returns (bool);
    function getUserIDO(address user) external view returns (UserIDO memory);

    function initialize(
        address factory_, 
        address insurancePool_,
        address stakingPool_,
        address platformTreasury_,
        address fundraiser_,
        address raisingToken_,
        address sellingToken_,
        uint8 insuranceFeeRate_,
        uint8 platformCommissionFeeRate_
    ) external;
    function initParams(
        uint256 totalSupply_,
        uint256 presalePrice_,
        uint256 publicSalePrice_,
        uint256 presaleAndEnrollStartTime_,
        uint256 presaleAndEnrollPeriod_,
        uint256 publicSaleDepositStartTime_,
        uint256 publicSaleDepositPeriod_,
        uint256 claimStartTime_,
        uint256 lockPeriod_,
        uint8 tgeUnlockRatio_
    ) external;
    function addPresaleWhitelist(address[] memory users, uint256[] memory quotas) external;
    function addPublicSaleList(address[] memory users, uint256[] memory quotas) external;
    function enroll() external;
    function presaleDeposit(uint256 buyQuota, bool buyInsurance) external;
    function publicSaleDeposit(bool buyInsurance, uint256 buyQuota, uint256 extraDeposit) external;
    function claim() external;
    function withdrawRaisingToken() external;
    function withdrawLeftQuotas() external;
    function callbackFromInsurance(uint256 transferAmount) external;
}