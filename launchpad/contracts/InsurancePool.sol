// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./interfaces/IInsurancePool.sol";
import "./interfaces/IIdoPoolFactory.sol";
import "./interfaces/IIdoPool.sol";
import "./interfaces/IERC20.sol";
import "./libraries/TransferHelper.sol";
import "@agniswap/core/contracts/libraries/FullMath.sol";

contract InsurancePool is IInsurancePool {
    using FullMath for uint256;

    address public override factory;
    mapping(address => bool) public override isRegisteredPool;
    mapping(address => uint256) public override totalNeedToPayByToken;

    InsuranceDetail[] private _insuranceDetails;
    mapping(address => IdoPoolInfo) private _idoPoolInfos;
    mapping(address => uint256[]) private _getInsuranceIdsByUser;

    constructor(address factory_) {
        factory = factory_;
    }

    function getInsuranceDetail(uint256 insuranceId) external view override returns (InsuranceDetail memory) {
        return _insuranceDetails[insuranceId];
    }

    function getInsuranceIdsByUser(address user) external view override returns (uint256[] memory) {
        return _getInsuranceIdsByUser[user];
    }

    function getIdoPoolInfo(address pool) external view override returns (IdoPoolInfo memory) {
        return _idoPoolInfos[pool];
    }

    function registerIdoPool(address idoPool) external override {
        require(msg.sender == factory, "forbidden");
        require(isRegisteredPool[idoPool] == false, "duplicate registration");
        
        isRegisteredPool[idoPool] = true;
        IIdoPool pool = IIdoPool(idoPool);
        IdoPoolInfo memory info = _idoPoolInfos[idoPool];
        info.paymentToken = pool.raisingToken();
        info.presalePrice = pool.presalePrice();
        info.publicSalePrice = pool.publicSalePrice();

        uint8 sellingTokenDecimals = IERC20(pool.sellingToken()).decimals();
        info.sellingTokenExp = uint256(10 ** sellingTokenDecimals);

        _idoPoolInfos[idoPool] = info;
        emit IdoPoolRegistered(idoPool);
    }

    function insure(address user, uint256 buyQuota, uint256 price, bool isPresale) external override returns (uint256 insuranceId) {
        require(isRegisteredPool[msg.sender], "forbidden");
        insuranceId = _insuranceDetails.length;
        InsuranceDetail memory detail = InsuranceDetail({
            idoPool: msg.sender,
            token: IIdoPool(msg.sender).raisingToken(),
            user: user,
            buyQuota: buyQuota,
            price: price,
            lossClaimed: false
        });
        _insuranceDetails.push(detail);
        _getInsuranceIdsByUser[user].push(insuranceId);

        IdoPoolInfo memory poolInfo = _idoPoolInfos[msg.sender];
        if (isPresale) {
            poolInfo.presaleTotalQuota += buyQuota;
        }else {
            poolInfo.publicSaleTotalQuota += buyQuota;
        }
        _idoPoolInfos[msg.sender] = poolInfo;

        emit Insured(detail.idoPool, detail.token, user, buyQuota, price, insuranceId);
    }

    // The average price update by the keeper should have the same unit and precision as the prices for private sales and public sales.
    function setAvgPrice(address pool, uint256 avgPrice) external override {
        require(avgPrice > 0,"invlalid avg price");
        require(msg.sender == IIdoPoolFactory(factory).keeper(), "forbidden");
        require(isRegisteredPool[pool], "unregistered");

        IdoPoolInfo memory poolInfo = _idoPoolInfos[pool];
        require(poolInfo.avgPrice == 0, "pool avg price already set");
        poolInfo.avgPrice = avgPrice;

        uint256 needToPay;
        if (avgPrice < poolInfo.presalePrice) {
            uint256 needToPayPresale = poolInfo.presaleTotalQuota.mulDiv(poolInfo.presalePrice - avgPrice, poolInfo.sellingTokenExp);
            uint256 needToPayPublicSale = poolInfo.publicSaleTotalQuota.mulDiv(poolInfo.publicSalePrice - avgPrice, poolInfo.sellingTokenExp);
            needToPay = needToPayPresale + needToPayPublicSale;
        } else if (avgPrice < poolInfo.publicSalePrice) {
            needToPay = poolInfo.publicSaleTotalQuota.mulDiv(poolInfo.publicSalePrice - avgPrice, poolInfo.sellingTokenExp);
        } 
        
        uint256 needTransferFromIdoPool;
        if (needToPay > 0) {
            poolInfo.needToPay = needToPay;
            uint256 totalNeedToPay = totalNeedToPayByToken[poolInfo.paymentToken];
            totalNeedToPay += needToPay;
            totalNeedToPayByToken[poolInfo.paymentToken] = totalNeedToPay;

            uint256 balanceOfThis = IERC20(poolInfo.paymentToken).balanceOf(address(this));
            if (balanceOfThis < totalNeedToPay) {
                needTransferFromIdoPool = totalNeedToPay - balanceOfThis;
            }
        }
        _idoPoolInfos[pool] = poolInfo;

        IIdoPool(pool).callbackFromInsurance(needTransferFromIdoPool); // callback IDO pool
        require(IERC20(poolInfo.paymentToken).balanceOf(address(this)) >= totalNeedToPayByToken[poolInfo.paymentToken], "not enough balance");
    }

    function claimLoss(uint256 insuranceId) external override {
        InsuranceDetail memory detail = _insuranceDetails[insuranceId];
        IdoPoolInfo memory poolInfo = _idoPoolInfos[detail.idoPool];

        require(poolInfo.needToPay > 0, "nothing need to pay");
        require(detail.price > poolInfo.avgPrice, "lower buyPrice");
        require(!detail.lossClaimed, "already claimed");

        uint256 payAmount = detail.buyQuota.mulDiv(detail.price - poolInfo.avgPrice, poolInfo.sellingTokenExp);
        TransferHelper.safeTransfer(poolInfo.paymentToken, detail.user, payAmount);
        detail.lossClaimed = true;
        _insuranceDetails[insuranceId] = detail;

        totalNeedToPayByToken[poolInfo.paymentToken] -= payAmount;

        emit LossClaimed(msg.sender, detail.user, poolInfo.paymentToken, insuranceId, payAmount);
    }
}