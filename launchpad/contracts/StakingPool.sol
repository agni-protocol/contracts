// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./interfaces/IStakingPool.sol";
import "./interfaces/IWMNT.sol";
import "./interfaces/IScoreCalculator.sol";
import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract StakingPool is IStakingPool, Ownable {
    address public override WMNT;
    address public override scoreCalculator;
    uint256 public override lockPeriod;
    mapping(address => bool) public override isStakingToken;
    mapping(address => uint256) public override getUserTier;
    mapping(address => uint256) public override getUserScore;

    uint256[] private tierScores;
    StakeInfo[] private stakeInfos;

    receive() external payable {}

    constructor(
        address WMNT_,
        address scoreCalculator_, 
        uint256 lockPeriod_,
        uint256[] memory tierScores_
    ) {
        WMNT = WMNT_;
        scoreCalculator = scoreCalculator_;
        lockPeriod = lockPeriod_;
        tierScores = tierScores_;
    }

    function getScoreByTier(uint256 tier) public view override returns (uint256 score) {
        if (tier == 0 || tier > tierScores.length) {
            score = 0;
        } else {
            score = tierScores[tier - 1];
        }
    }

    function getTierByScore(uint256 score) public view override returns (uint256 tier) {
        if (score == 0 || tierScores.length == 0){
            return 0;
        }

        for (uint256 i = tierScores.length - 1; i >= 0; i--) {
            if (score >= tierScores[i]) {
                tier = i + 1;
                break;
            }
        }
    }

    function getStakeInfo(uint256 stakeId) external view override returns (StakeInfo memory) {
        return stakeInfos[stakeId];
    }
    
    // add WMNT means support native token MNT
    function addStakingToken(address token) external override onlyOwner {
        require(token != address(0), "zero address");
        require(!isStakingToken[token], "already added");

        isStakingToken[token] = true;
        emit StakingTokenAdded(token);
    }

    function removeStakingToken(address token) external override onlyOwner {
        require(token != address(0), "zero address");
        require(isStakingToken[token], "token not found");
        isStakingToken[token] = false;
        emit StakingTokenRemoved(token);
    }

    function updateLockPeriod(uint256 newPeriod) external override onlyOwner {
        require(newPeriod > 0, "zero");
        emit LockPeriodUpdated(lockPeriod, newPeriod);
        lockPeriod = newPeriod;
    }

    function updateScoreCalculator(address newCalculator) external override onlyOwner {
        require(newCalculator != address(0), "zero address");
        emit ScoreCalculatorUpdated(scoreCalculator, newCalculator);
        scoreCalculator = newCalculator;
    }

    function setTierScore(uint256 tier, uint256 score) external override onlyOwner {
        require(score > 0, "zero score");
        require(tier > 0, "zero tier");
        uint256 tierIndex = tier - 1;

        uint256 tierSize = tierScores.length;
        require(tierIndex <= tierSize, "out of bounds");

       if (tierIndex == tierSize) { // add new tier score
            require(score > tierScores[tierSize - 1], "must greater than last tier score");
            tierScores.push(score);
            emit TierScoreUpdated(tier, 0, score);
        } else if(tierIndex == tierSize -1){ // max tier update
            if (tierSize == 1){ // only one tier
                uint256 oldScore = tierScores[tierIndex];
                tierScores[tierIndex] = score;
                emit TierScoreUpdated(tier, oldScore, score);
            }else{
                uint256 oldScore = tierScores[tierIndex];
                require(score > tierScores[tierIndex - 1],"new score must greater than pre tier score");
                tierScores[tierIndex] = score;
                emit TierScoreUpdated(tier, oldScore, score);
            }
        }else { // reset other old tier score
            if (tierIndex == 0){ // first tier
                uint256 oldScore = tierScores[tierIndex];
                require(score < tierScores[tierIndex + 1],"new score must less than next tier score");
                tierScores[tierIndex] = score;
                emit TierScoreUpdated(tier, oldScore, score);
            }else{
                require(score > tierScores[tierIndex - 1] && score < tierScores[tierIndex + 1], "score must between [tierIndex-1,tierIndex+1] score");
                uint256 oldScore = tierScores[tierIndex];
                tierScores[tierIndex] = score;
                emit TierScoreUpdated(tier, oldScore, score);
            }
        }
    }

    function stake(address token, uint256 tokenIdOrAmount) public override returns (uint256 stakeId) {
        bool isERC721;
        try IERC721(token).supportsInterface(type(IERC721).interfaceId) returns (bool) {
            isERC721 = true;
            IERC721(token).safeTransferFrom(msg.sender, address(this), tokenIdOrAmount);
        } catch  {
            isERC721 = false;
            TransferHelper.safeTransferFrom(token, msg.sender, address(this), tokenIdOrAmount);
        }

        return _stake(token, tokenIdOrAmount,isERC721);
    }

    function stakeNativeToken() external payable override returns (uint256 stakeId) {
        uint256 amount = msg.value;
        IWMNT(WMNT).deposit{value: amount}();
        return _stake(WMNT, amount, false);
    }

    function unstake(uint256[] calldata stakeIds) external override   {
        require(stakeIds.length <= 10, "stakeIds length oversize");

        for (uint i = 0; i < stakeIds.length; i++) {
            uint256 stakeId = stakeIds[i];

            require(stakeId < stakeInfos.length, "stakeId not found");
            StakeInfo memory stakeInfo = stakeInfos[stakeId];
            require(stakeInfo.user == msg.sender, "sender isn't the user");
            require(stakeInfo.unlockTime <= block.timestamp, "not reach unlock time");
            require(!stakeInfo.unstaked, "already unstaked");

            uint256 newUserScore = getUserScore[msg.sender] - stakeInfo.score;
            uint256 newTier = getTierByScore(newUserScore);
            getUserScore[msg.sender] = newUserScore;
            getUserTier[msg.sender] = newTier;
            stakeInfo.unstaked = true;
            stakeInfos[stakeId] = stakeInfo;

            if (stakeInfo.isERC721) {
                IERC721(stakeInfo.token).safeTransferFrom(address(this), msg.sender, stakeInfo.tokenIdOrAmount);
            } else {
                if (stakeInfo.token == WMNT) {
                    IWMNT(WMNT).withdraw(stakeInfo.tokenIdOrAmount);
                    TransferHelper.safeTransferMNT(msg.sender, stakeInfo.tokenIdOrAmount);
                } else {
                    TransferHelper.safeTransfer(stakeInfo.token, msg.sender, stakeInfo.tokenIdOrAmount);
                }
            }

            emit Unstaked(msg.sender, stakeId, stakeInfo.tokenIdOrAmount, newUserScore, newTier);
        }
    }

    function _stake(address token, uint256 tokenIdOrAmount, bool isERC721) internal returns (uint256 stakeId) {
        require(isStakingToken[token], "unsupported token");
        uint256 score = IScoreCalculator(scoreCalculator).calculate(token, tokenIdOrAmount);
        require(score > 0, "zero score");
        
        address user = msg.sender;
        uint256 newUserScore = getUserScore[user] + score;
        uint256 newTier = getTierByScore(newUserScore);
        require(newTier > 0, "zero tier");

        getUserScore[user] = newUserScore;
        getUserTier[user] = newTier;
        
        stakeId = stakeInfos.length;
        StakeInfo memory stakeInfo = StakeInfo({
            user: user,
            token: token,
            tokenIdOrAmount: tokenIdOrAmount,
            unlockTime: block.timestamp + lockPeriod,
            score: score,
            unstaked: false,
            isERC721: isERC721
        });
        stakeInfos.push(stakeInfo);

        emit Staked(user, token, tokenIdOrAmount, stakeInfo.unlockTime, score, newTier, stakeId);
    }
}