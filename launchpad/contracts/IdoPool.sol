// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./interfaces/IIdoPool.sol";
import "./interfaces/IIdoPoolFactory.sol";
import "./interfaces/IInsurancePool.sol";
import "./interfaces/IStakingPool.sol";
import "./interfaces/IERC20.sol";
import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@agniswap/core/contracts/libraries/FullMath.sol";


contract IdoPool is IIdoPool, Initializable {
    using FullMath for uint256;

    address public override factory;
    address public override raisingToken; // the address of the fundraising token.
    address public override sellingToken; // the address of the token being sold.
    address public override insurancePool; // the address of the insurance pool.
    address public override stakingPool; // the address of the staking pool.
    address public override fundraiser; // the address of the fundraiser.
    address public override platformTreasury; // the address of the platform treasury, used for collecting fees.

    uint256 public override totalSupply; // the total supply of tokens for sale.
    uint256 public override totalLeftQuotas; // the total remaining quota available for distribution.
    uint256 public override totalBuyedByUsers; // the total amount of tokens purchased by users.
    uint256 public override totalLockByInsurance; // the total amount locked due to purchasing insurance.
    uint256 public override deductedByInsurance; // the deducted amount callback by insurance.
    uint256 public override totalExtraDeposit; // the total extra deposit.
    uint256 public override totalRaised; // the total amount raised.
    uint256 public override presalePrice; // The presale price has the same decimals as the fundraising token.
    uint256 public override publicSalePrice; // The public price has the same decimals as the fundraising token.
    uint256 public override presaleAndEnrollStartTime;
    uint256 public override presaleAndEnrollEndTime;
    uint256 public override publicSaleDepositStartTime;
    uint256 public override publicSaleDepositEndTime;
    uint256 public override claimStartTime;
    uint256 public override unlockTillTime;
    uint256 public override minBuyQuota;

    uint8 public override platformCommissionFeeRate; // platform commission fee rate as a percentage, 0-100
    uint8 public override insuranceFeeRate; // insurance fee rate as a percentage, 0-100
    uint8 public override tgeUnlockRatio; // the TGE unlock ratio as a percentage, 0-100


    mapping(address => uint256) public override getPresaleQuota; // presale allocation limit
    mapping(address => uint256) public override getPublicSaleQuota; // publicsale allocation limit
    mapping(address => bool) public override isEnrolled; // user enroll status
    mapping(address => bool) public override presaleDeposited;
    mapping(address => bool) public override publicSaleDeposited; 

    mapping(address => UserIDO) private _userIdoMap;
    bool private _unlockedFromInsurance;
    bool private _lastTotalValuesUpdated;
    bool public scam; // Is the project a scam?
    
    uint256 private _withdrawnByfundraiser; // The amount of funds raised that has been withdrawn.
    uint256 private _sellingTokenExp; // 10 ** sellingTokenDecimals

    modifier onlyKeeper() {
        address keeper = IIdoPoolFactory(factory).keeper();
        require(msg.sender == keeper, "only keeper");
        _;
    }

    function getUserIDO(address user) external view override returns (UserIDO memory) {
        return _userIdoMap[user];
    }

    function initialize(
        address factory_, 
        address insurancePool_,
        address stakingPool_,
        address fundraiser_,
        address platformTreasury_,
        address raisingToken_,
        address sellingToken_,
        uint8 insuranceFeeRate_,
        uint8 platformCommissionFeeRate_
    ) external override initializer {
        factory = factory_;
        insurancePool = insurancePool_;
        stakingPool = stakingPool_;
        fundraiser = fundraiser_;
        platformTreasury = platformTreasury_;
        raisingToken = raisingToken_;
        sellingToken = sellingToken_;
        insuranceFeeRate = insuranceFeeRate_;
        platformCommissionFeeRate = platformCommissionFeeRate_;

        uint8 sellingTokenDecimals = IERC20(sellingToken_).decimals();
        _sellingTokenExp = uint256(10 ** sellingTokenDecimals);
        minBuyQuota = uint256(10 ** sellingTokenDecimals);
    }

    // Since there are too many parameters needed for initialization, it is split into two functions to avoid "Stack too deep" error.
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
    ) external override {
        require(msg.sender == factory, "forbidden");
        totalSupply = totalSupply_;
        presalePrice = presalePrice_;
        publicSalePrice = publicSalePrice_;

        presaleAndEnrollStartTime = presaleAndEnrollStartTime_;
        presaleAndEnrollEndTime = presaleAndEnrollStartTime_ + presaleAndEnrollPeriod_;
        require(presaleAndEnrollEndTime > presaleAndEnrollStartTime,"invalid presale time");

        publicSaleDepositStartTime = publicSaleDepositStartTime_;
        publicSaleDepositEndTime = publicSaleDepositStartTime_ + publicSaleDepositPeriod_;
        require(publicSaleDepositEndTime > publicSaleDepositStartTime,"invalid public sale time");

        claimStartTime = claimStartTime_;
        require(claimStartTime > publicSaleDepositEndTime,"invalid claim time");

        unlockTillTime = claimStartTime_ + lockPeriod_;
        tgeUnlockRatio = tgeUnlockRatio_;
        totalLeftQuotas = totalSupply_;
    }

    // Add whitelist for presale. Can be called multiple times. 
    // If duplicate users are found, the latest one will overwrite the previous ones.
    // quota needs to extend the precision of the sold tokens, 
    // for example, if the precision of the sold tokens is 18 and the allocated quota is 200, then quota = 200 * 10^18
    function addPresaleWhitelist(address[] memory users, uint256[] memory quotas) external override onlyKeeper {
        require(block.timestamp < presaleAndEnrollStartTime, "over presale start time");
        require(users.length == quotas.length, "length not the same");

        uint256 totalLeftQuotas_ = totalLeftQuotas;
        uint256 tempQuota_;
        for (uint256 i = 0; i < users.length; i++) {
            tempQuota_ = getPresaleQuota[users[i]];
            
            if (tempQuota_ > 0) totalLeftQuotas_ += tempQuota_;

            getPresaleQuota[users[i]] = quotas[i];
            totalLeftQuotas_ -= quotas[i];
        }
        totalLeftQuotas = totalLeftQuotas_;
        emit PresaleWhiteListSet(users, quotas);
    }

    // Add whitelist for public sale.
    function addPublicSaleList(address[] memory users, uint256[] memory quotas) external override onlyKeeper {
        require(block.timestamp > presaleAndEnrollEndTime, "need after presale");
        require(block.timestamp < publicSaleDepositStartTime,"need before public sale");
        require(users.length == quotas.length, "length not the same");

        uint256 totalQuotas_;
        for (uint256 i = 0; i < users.length; i++) {
            require(isEnrolled[users[i]], "not enrolled");
            require(getPublicSaleQuota[users[i]] == 0, "repeat user");
            getPublicSaleQuota[users[i]] = quotas[i];
            totalQuotas_ += quotas[i];
        }
        require(totalQuotas_ <= totalSupply - totalBuyedByUsers, "over left quotas");
        totalLeftQuotas = totalSupply - totalBuyedByUsers - totalQuotas_;
        emit PublicSaleListSet(users, quotas);
    }

   // Public sale registration
    function enroll() external override {
        require(block.timestamp >= presaleAndEnrollStartTime, "not start");
        require(block.timestamp <= presaleAndEnrollEndTime, "end");
        require(!isEnrolled[msg.sender], "already enrolled");

        uint256 userTier =  IStakingPool(stakingPool).getUserTier(msg.sender);
        require(userTier > 0, "not staked");

        isEnrolled[msg.sender] = true;
        emit UserEnrolled(msg.sender);
    }

    // Users start presale 
    function presaleDeposit(uint256 buyQuota, bool buyInsurance) external override {
        require(buyQuota > minBuyQuota, "must greater than min buyquota");
        require(block.timestamp >= presaleAndEnrollStartTime, "not start");
        require(block.timestamp <= presaleAndEnrollEndTime, "end");
        require(!presaleDeposited[msg.sender], "already presale deposited");
        require(getPresaleQuota[msg.sender] >= buyQuota, "over user's quota");

        uint256 payForQuota = buyQuota.mulDiv(presalePrice, _sellingTokenExp);
        TransferHelper.safeTransferFrom(raisingToken, msg.sender, address(this), payForQuota);

        totalRaised += payForQuota; // add to the total amount raised.

        UserIDO storage userIDO = _userIdoMap[msg.sender];
        userIDO.totalPurchased += buyQuota;
        userIDO.tgeUnlocked += buyQuota * tgeUnlockRatio / 100;

        if (buyInsurance && insuranceFeeRate > 0) {
            uint256 insuranceFee = payForQuota * insuranceFeeRate / 100;
            TransferHelper.safeTransferFrom(raisingToken, msg.sender, insurancePool, insuranceFee);
            uint256 insuranceId = IInsurancePool(insurancePool).insure(msg.sender, buyQuota, presalePrice, true);
            userIDO.insuranceIds.push(insuranceId);
            totalLockByInsurance += payForQuota; // add to the total locked amount by insurance.
        }

        totalBuyedByUsers += buyQuota; // add to to total purchased by users.
        presaleDeposited[msg.sender] = true; // set user presale status
        emit PresaleDeposited(msg.sender, buyQuota, buyInsurance);
    }

    // Users start publicsale 
    function publicSaleDeposit(bool buyInsurance, uint256 buyQuota, uint256 extraDeposit) external override {
        require(buyQuota > minBuyQuota, "must greater than min buyquota");
        require(block.timestamp >= publicSaleDepositStartTime, "not start");
        require(block.timestamp <= publicSaleDepositEndTime, "end");
        require(!publicSaleDeposited[msg.sender], "already public sale deposited");
        uint256 quotaLimit_ = getPublicSaleQuota[msg.sender];
        require(quotaLimit_ >= buyQuota, "over user's left quota");
        
        uint256 payForQuota = buyQuota.mulDiv(publicSalePrice, _sellingTokenExp);
        totalRaised += payForQuota; // add to the total amount raised.
        if (buyQuota == quotaLimit_) { // The extra deposit amount is only effective when the actual purchased amount reaches the allocated quota.
            require(payForQuota * 3 >= extraDeposit, "extraDeposit over limit");
            TransferHelper.safeTransferFrom(raisingToken, msg.sender, address(this), payForQuota + extraDeposit);
            totalExtraDeposit += extraDeposit;  // add to the total amount for extra deposit.
        } else {
            TransferHelper.safeTransferFrom(raisingToken, msg.sender, address(this), payForQuota);
            extraDeposit = 0;
        }

        UserIDO storage userIDO = _userIdoMap[msg.sender];
        userIDO.totalPurchased += buyQuota;
        userIDO.tgeUnlocked += buyQuota * tgeUnlockRatio / 100;
        userIDO.refundable = extraDeposit; // The extra deposit amount is recorded as the refundable amount.

        if (buyInsurance && insuranceFeeRate > 0) {
            uint256 insuranceFee = payForQuota * insuranceFeeRate / 100;
            TransferHelper.safeTransferFrom(raisingToken, msg.sender, insurancePool, insuranceFee);
            uint256 insuranceId = IInsurancePool(insurancePool).insure(msg.sender, buyQuota, publicSalePrice, false);
            userIDO.insuranceIds.push(insuranceId);
            totalLockByInsurance += payForQuota; // add to the total locked amount by insurance.
        }

        totalBuyedByUsers += buyQuota; // add to to total purchased by users.
        publicSaleDeposited[msg.sender] = true; // set user publicsale status
        emit PublicSaleDeposited(msg.sender, buyQuota, extraDeposit, buyInsurance);
    }

    // After the public sale ends, update the final data
    function updateTotalValue() external onlyKeeper {
        _updateLastTotalValues();
    }

    // When a user redeems their investment, calculate the extra deposit proceeds
    function claim() external override {
        require(block.timestamp >= claimStartTime, "not claim time");

        _updateLastTotalValues();

        UserIDO memory userIDO = _userIdoMap[msg.sender];
        uint256 refundAmount;
        if (userIDO.refundable > 0) {
            // The total remaining quota after the public subscription ends
            uint256 totalLeftAfterPublicSale = totalSupply - totalBuyedByUsers;
            if (totalLeftAfterPublicSale > 0) {
                uint256 totalLeftValue = totalLeftAfterPublicSale.mulDiv(publicSalePrice, _sellingTokenExp);
                uint256 extraQuota; // Additional quota available for purchase
                if (totalLeftValue <= totalExtraDeposit) {
                   // If the remaining total value is less than or equal to the total amount of extra deposit, 
                   // then all the remaining quota will be allocated to all users who made extra deposit.
                   // Each user will receive a portion of the remaining quota based on the ratio of their extra deposit amount 
                   // to the total extra deposit amount.
                    extraQuota = totalLeftAfterPublicSale.mulDiv(userIDO.refundable, totalExtraDeposit);
                } else {
                    // If the remaining total value is greater than the total amount of extra deposit, 
                    // then all users who made extra deposit will be eligible to receive additional subscription tokens.

                    // extraQuota = extra deposit amount / public price
                    extraQuota = userIDO.refundable.mulDiv(_sellingTokenExp, publicSalePrice);
                }
                // The refundable amount should be deducted by the portion used for extra deposit.
                userIDO.refundable -= extraQuota.mulDiv(publicSalePrice, _sellingTokenExp);
                userIDO.totalPurchased += extraQuota;
                userIDO.tgeUnlocked += extraQuota * tgeUnlockRatio / 100;
            }
            if (userIDO.refundable > 0) {
                refundAmount = userIDO.refundable;
                TransferHelper.safeTransfer(raisingToken, msg.sender, userIDO.refundable);
                userIDO.refundable = 0; // // After the refund, set it to zero to avoid duplicate refunds during the next claim.
            }
        }

        // To calculate the unlocked amount but not yet claimed
        uint256 claimableAmount;
        if (block.timestamp >= unlockTillTime) {
            claimableAmount = userIDO.totalPurchased - userIDO.claimed;
        } else {
            uint256 lockFromStart = userIDO.totalPurchased - userIDO.tgeUnlocked;
            if (lockFromStart > 0) {
                uint256 wholeTimeWindow = unlockTillTime - claimStartTime;
                uint256 unlockTimeWindow = block.timestamp - claimStartTime;
                claimableAmount = lockFromStart * unlockTimeWindow / wholeTimeWindow + userIDO.tgeUnlocked - userIDO.claimed;
            }
        }
        if (claimableAmount > 0) {
            TransferHelper.safeTransfer(sellingToken, msg.sender, claimableAmount);
            userIDO.claimed += claimableAmount;
        }

        _userIdoMap[msg.sender] = userIDO;

        emit Claimed(msg.sender, claimableAmount, refundAmount);
    }

    function refundable(address user) public view returns (uint256,uint256){
        // need lastTotalValuesUpdated first
        if (!_lastTotalValuesUpdated) {
            return (0, 0);
        }

        UserIDO memory userIDO = _userIdoMap[user];
        uint256 refundableAmount = userIDO.refundable;
        uint256 extraQuota; 

        if (refundableAmount > 0) {
            uint256 totalLeftAfterPublicSale = totalSupply - totalBuyedByUsers;
            if (totalLeftAfterPublicSale > 0) {
                uint256 totalLeftValue = totalLeftAfterPublicSale.mulDiv(publicSalePrice, _sellingTokenExp);
                if (totalLeftValue <= totalExtraDeposit) {
                    extraQuota = totalLeftAfterPublicSale.mulDiv(refundableAmount, totalExtraDeposit);
                } else {
                    extraQuota = refundableAmount.mulDiv(_sellingTokenExp, publicSalePrice);
                }
                refundableAmount -= extraQuota.mulDiv(publicSalePrice, _sellingTokenExp);
            }
        }
        return (refundableAmount, extraQuota);
    }

    function claimable(address user) public view returns (uint256){
        // need lastTotalValuesUpdated first
        if (!_lastTotalValuesUpdated) {
            return 0;
        }

        uint256 claimableAmount;
        UserIDO memory userIDO = _userIdoMap[user];
        if (userIDO.totalPurchased <=0){
            return 0;
        }

        uint256 tgeUnlocked = userIDO.tgeUnlocked;
        uint256 totalPurchased = userIDO.totalPurchased;

        // calc extraQuota
        (, uint256 extraQuota) = refundable(user);
        if (extraQuota >0 ) {
            totalPurchased +=  extraQuota;
            tgeUnlocked += extraQuota * tgeUnlockRatio / 100;
        }
        
        if (block.timestamp >= unlockTillTime) {
            claimableAmount = totalPurchased - userIDO.claimed;
        } else {
            uint256 lockFromStart = totalPurchased - tgeUnlocked;
            if (lockFromStart > 0) {
                uint256 wholeTimeWindow = unlockTillTime - claimStartTime;
                uint256 unlockTimeWindow = block.timestamp - claimStartTime;
                claimableAmount =  lockFromStart * unlockTimeWindow / wholeTimeWindow + tgeUnlocked - userIDO.claimed;
            }
        }
        return claimableAmount;
    }

    // Callback from the insurance pool contract, when the pool's funds are not sufficient to pay out, 
    // the lacking funds are transferred from current pool to insurance pool.
    function callbackFromInsurance(uint256 transferAmount, bool _scam) external override {
        require(!_unlockedFromInsurance,"already callback by insurance");
        require(msg.sender == insurancePool, "forbidden");
        require(transferAmount <= totalLockByInsurance, "too much transferAmount");

        if (transferAmount >0) {
            TransferHelper.safeTransfer(raisingToken, insurancePool, transferAmount);
        }
        emit CallbackFromInsurance(address(this),transferAmount);

        _unlockedFromInsurance = true;
        deductedByInsurance += transferAmount;
        scam = _scam;

        // If the project is scam, the remaining locked funds need to be put into the insurance pool
        if (scam){
            uint256 leftLockByInsurance = totalLockByInsurance - transferAmount;
            TransferHelper.safeTransfer(raisingToken, insurancePool, leftLockByInsurance);
            emit CallbackFromInsuranceScam(address(this), leftLockByInsurance);
        }
    }


   // Withdraw fundraising tokens can only be call by the fundraiser address.
    function withdrawRaisingToken() external override {
        require(msg.sender == fundraiser, "forbidden");
        require(block.timestamp >= claimStartTime, "not claim time");

        _updateLastTotalValues();

        uint256 withdrawable = totalRaised;
        // After receiving the callback from the insurance pool, if the project party is not scam, it can only withdraw the locked part of the insurance.
        if (!_unlockedFromInsurance && !scam) {
            withdrawable -= totalLockByInsurance;
        } else {
            withdrawable -= deductedByInsurance;
        }
        
        withdrawable -= _withdrawnByfundraiser; // The withdrawn portion needs to be subtracted from the total locked amount.
        require(withdrawable > 0, "zero withdrawable");

        _withdrawnByfundraiser += withdrawable; // Add the withdrawn portion to the accumulated amount.

        if (platformCommissionFeeRate > 0) { 
            uint256 commissionFee = withdrawable * platformCommissionFeeRate / 100;
            TransferHelper.safeTransfer(raisingToken, platformTreasury, commissionFee);
            withdrawable -= commissionFee;
        }
        TransferHelper.safeTransfer(raisingToken, fundraiser, withdrawable);
    }

    // Withdraw the tokens of the unsold projects.
    function withdrawLeftQuotas() external override {
        require(msg.sender == fundraiser, "forbidden");
        require(block.timestamp >= claimStartTime, "not claim time");

        _updateLastTotalValues();
        
        if (totalLeftQuotas > 0) {
            TransferHelper.safeTransfer(sellingToken, fundraiser, totalLeftQuotas);
            totalLeftQuotas = 0;
        }
    }

   // After the public sale ends, only need to update the total amount raised and the remaining unsold project tokens once.
    function _updateLastTotalValues() internal {
        require(block.timestamp > publicSaleDepositEndTime, "public sale not end");

        if (!_lastTotalValuesUpdated) {
            _lastTotalValuesUpdated = true;
            totalLeftQuotas = 0;
            uint256 totalLeftAfterPublicSale = totalSupply - totalBuyedByUsers;
            if (totalLeftAfterPublicSale > 0) {
                uint256 totalLeftValue = totalLeftAfterPublicSale.mulDiv(publicSalePrice, _sellingTokenExp);
                if (totalLeftValue <= totalExtraDeposit) {
                    totalRaised += totalLeftValue;
                } else {
                    totalRaised += totalExtraDeposit;
                    totalLeftQuotas = (totalLeftValue - totalExtraDeposit).mulDiv(_sellingTokenExp, publicSalePrice);
                }
            }
        }
    }
}