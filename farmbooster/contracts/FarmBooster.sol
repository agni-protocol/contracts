// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/IAgniPool.sol';
import './interfaces/IMasterChefV3.sol';
import './libraries/IterateMapping.sol';
import './interfaces/IAgniPool.sol';

contract FarmBooster is Ownable {
    using IterableMapping for ItMap;

    /// @notice Agni token.
    address public immutable AGNI;
    /// @notice Agni pool.
    address public immutable AGNI_POOL;
    /// @notice MasterChef V3 contract.
    IMasterChefV3 public immutable MASTER_CHEF_V3;

    /// @notice Initialize the totalLockedAmount.
    bool initialization;

    /// @notice Agni Pool total locked cake amount.
    uint256 public totalLockedAmount;

    /// @notice The latest total locked cake amount In AgniPool
    uint256 latestTotalLockedAmountInAgniPool;

    struct UserLockedInfo {
        bool init;
        uint256 lockedAmount;
    }

    /// @notice Record user lockedAmount in cake pool
    mapping(address => UserLockedInfo) public userLockedInfos;

    /// @notice Maximum allowed boosted position numbers
    uint256 public MAX_BOOST_POSITION;
    /// @notice limit max boost
    uint256 public cA;
    /// @notice include 1e4
    uint256 public constant MIN_CA = 1e4;
    /// @notice include 1e5
    uint256 public constant MAX_CA = 1e5;
    /// @notice cA precision
    uint256 public constant CA_PRECISION = 1e5;
    /// @notice controls difficulties
    uint256 public cB;
    /// @notice not include 0
    uint256 public constant MIN_CB = 0;
    /// @notice include 50
    uint256 public constant MAX_CB = 1e8;
    /// @notice cB precision
    uint256 public constant CB_PRECISION = 1e4;
    /// @notice MCV3 basic boost factor, none boosted user"s boost factor
    uint256 public constant BOOST_PRECISION = 100 * 1e10;
    /// @notice MCV3 Hard limit for maxmium boost factor
    uint256 public constant MAX_BOOST_PRECISION = 200 * 1e10;
    /// @notice Average boost ratio precision
    uint256 public constant BOOST_RATIO_PRECISION = 1e5;
    /// @notice Agni pool BOOST_WEIGHT precision
    uint256 public constant BOOST_WEIGHT_PRECISION = 100 * 1e10; // 100%

    /// @notice Override global cB for special pool pid.
    mapping(uint256 => uint256) public cBOverride;

    /// @notice The whitelist of pools allowed for farm boosting.
    mapping(uint256 => bool) public whiteList;

    /// @notice Record whether the farm booster has been turned on, in order to save gas.
    mapping(uint256 => bool) public everBoosted;

    /// @notice Info of each pool user.
    mapping(address => ItMap) public userInfo;

    event UpdateMaxBoostPosition(uint256 max);
    event UpdateCA(uint256 oldCA, uint256 newCA);
    event UpdateCB(uint256 oldCB, uint256 newCB);
    event UpdateCBOverride(uint256 pid, uint256 oldCB, uint256 newCB);
    event UpdateBoostFarms(uint256 pid, bool status);
    event AdjustTotalLockedAmount(bool down, uint256 amount);
    event ActiveFarmPool(address indexed user, uint256 indexed pid, uint256 indexed tokenId);
    event DeactiveFarmPool(address indexed user, uint256 indexed pid, uint256 indexed tokenId);
    event UpdatePoolBoostMultiplier(
        address indexed user,
        uint256 indexed pid,
        uint256 indexed tokenId,
        uint256 oldMultiplier,
        uint256 newMultiplier
    );
    event UpdateAgniPool(
        address indexed user,
        uint256 lockedAmount,
        uint256 lockedDuration,
        uint256 totalLockedAmount,
        uint256 maxLockDuration
    );

    /// @param _cake AGNI token contract address.
    /// @param _cakePool Agni Pool contract address.
    /// @param _v3 MasterChefV3 contract address.
    /// @param _max Maximum allowed boosted farm quantity.
    /// @param _cA Limit max boost.
    /// @param _cB Controls difficulties.
    constructor(address _cake, address _cakePool, IMasterChefV3 _v3, uint256 _max, uint256 _cA, uint256 _cB) {
        require(_max > 0 && _cA >= MIN_CA && _cA <= MAX_CA && _cB > MIN_CB && _cB <= MAX_CB, 'Invalid parameter');
        AGNI = _cake;
        AGNI_POOL = _cakePool;
        MASTER_CHEF_V3 = _v3;
        MAX_BOOST_POSITION = _max;
        cA = _cA;
        cB = _cB;
    }

    /// @notice Checks if the msg.sender is the cake pool.
    modifier onlyAgniPool() {
        require(msg.sender == AGNI_POOL, 'Not cake pool');
        _;
    }

    /// @notice Checks if the msg.sender is the MasterChef V3.
    modifier onlyMasterChefV3() {
        require(msg.sender == address(MASTER_CHEF_V3), 'Not MasterChef V3');
        _;
    }

    /// @notice Adjust the totalLockedAmount caused by inaccurate calculations.
    /// @param _down Down or up.
    /// @param _amount The amount need to be adjusted.
    function adjustTotalLockedAmount(bool _down, uint256 _amount) external onlyOwner {
        if (_down) {
            totalLockedAmount -= _amount;
        } else {
            totalLockedAmount += _amount;
        }
        emit AdjustTotalLockedAmount(_down, _amount);
    }

    /// @notice set maximum allowed boosted position numbers.
    /// @param _max MAX_BOOST_POSITION.
    function setMaxBoostPosition(uint256 _max) external onlyOwner {
        require(_max > 0, 'Can not be zero');
        MAX_BOOST_POSITION = _max;
        emit UpdateMaxBoostPosition(_max);
    }

    /// @notice Only allow whitelisted pids for farm boosting.
    /// @param _pid pool id(Masterchef V3 pool).
    /// @param _status farm pool allowed boosted or not.
    function setBoosterFarms(uint256 _pid, bool _status) external onlyOwner {
        if (_status && !everBoosted[_pid]) everBoosted[_pid] = true;
        whiteList[_pid] = _status;
        emit UpdateBoostFarms(_pid, _status);
    }

    /// @notice Limit max boost.
    /// @param _cA Max boost.
    function setCA(uint256 _cA) external onlyOwner {
        require(_cA >= MIN_CA && _cA <= MAX_CA, 'Invalid cA');
        uint256 temp = cA;
        cA = _cA;
        emit UpdateCA(temp, cA);
    }

    /// @notice Controls difficulties.
    /// @param _cB Difficulties.
    function setCB(uint256 _cB) external onlyOwner {
        require(_cB > MIN_CB && _cB <= MAX_CB, 'Invalid cB');
        uint256 temp = cB;
        cB = _cB;
        emit UpdateCB(temp, cB);
    }

    /// @notice Set cBOverride.
    /// @param _pid Pool pid.
    /// @param _cB Difficulties.
    function setCBOverride(uint256 _pid, uint256 _cB) external onlyOwner {
        // Can set cBOverride[pid] 0 when need to remove override value.
        require(_cB <= MAX_CB, 'Invalid cB');
        uint256 temp = cB;
        cBOverride[_pid] = _cB;
        emit UpdateCBOverride(_pid, temp, cB);
    }

    /// @notice Calculate totalLockedAmount and update UserLockedInfo.
    /// @dev This is to fix the totalLockedAmount issue in cake pool.
    /// @param _user User address.
    function updateTotalLockedAmount(address _user) internal {
        uint256 totalLockedAmountInAgniPool = IAgniPool(AGNI_POOL).totalLockedAmount();
        if (!initialization) {
            // Record the totalLockedAmount as the initial value after setting farm booster contract in cake pool.
            initialization = true;
            totalLockedAmount = totalLockedAmountInAgniPool;
            latestTotalLockedAmountInAgniPool = totalLockedAmountInAgniPool;
        }
        (, , , , , , , , uint256 userLockedAmount) = IAgniPool(AGNI_POOL).userInfo(_user);
        UserLockedInfo storage lockedInfo = userLockedInfos[_user];
        if (!lockedInfo.init) {
            lockedInfo.init = true;
            lockedInfo.lockedAmount = userLockedAmount;

            // Deposit cake into cake pool.
            if (totalLockedAmountInAgniPool >= latestTotalLockedAmountInAgniPool) {
                totalLockedAmount += totalLockedAmountInAgniPool - latestTotalLockedAmountInAgniPool;
            } else {
                // Withdraw cake from cake pool.
                totalLockedAmount -= latestTotalLockedAmountInAgniPool - totalLockedAmountInAgniPool;
            }
        } else {
            totalLockedAmount = totalLockedAmount - lockedInfo.lockedAmount + userLockedAmount;
            lockedInfo.lockedAmount = userLockedAmount;
        }
        latestTotalLockedAmountInAgniPool = totalLockedAmountInAgniPool;
    }

    /// @notice Update UserLockedInfo.
    /// @dev This will update the userLockedAmount for the users who had already locked cake in cake pool.
    /// @param _user User address.
    function updateUserLockedAmount(address _user) internal {
        UserLockedInfo storage lockedInfo = userLockedInfos[_user];
        if (initialization && !lockedInfo.init) {
            (, , , , , , , , uint256 userLockedAmount) = IAgniPool(AGNI_POOL).userInfo(_user);
            lockedInfo.init = true;
            lockedInfo.lockedAmount = userLockedAmount;
        }
    }

    /// @notice Agnipool operation(deposit/withdraw) automatically call this function.
    /// @param _user User address.
    /// @param _lockedAmount User locked amount in cake pool.
    /// @param _lockedDuration User locked duration in cake pool.
    /// @param _totalLockedAmount Total locked cake amount in cake pool.
    /// @param _maxLockDuration Maximum locked duration in cake pool.
    function onAgniPoolUpdate(
        address _user,
        uint256 _lockedAmount,
        uint256 _lockedDuration,
        uint256 _totalLockedAmount,
        uint256 _maxLockDuration
    ) external onlyAgniPool {
        updateTotalLockedAmount(_user);
        ItMap storage itmap = userInfo[_user];
        uint256 length = itmap.keys.length;
        if (length > 0) {
            uint256 avgDuration = avgLockDuration();
            for (uint256 i = 0; i < length; i++) {
                uint256 tokenId = itmap.keys[i];
                (uint128 liquidity, address user, uint256 pid, ) = getUserPositionInfo(tokenId);
                if (_user == user) _updateBoostMultiplier(itmap, user, pid, tokenId, avgDuration, liquidity);
            }
        }
        emit UpdateAgniPool(_user, _lockedAmount, _lockedDuration, _totalLockedAmount, _maxLockDuration);
    }

    /// @notice Update user boost multiplier, only for MasterChef V3.
    /// @param _tokenId Token Id of position NFT.
    function updatePositionBoostMultiplier(uint256 _tokenId) external onlyMasterChefV3 returns (uint256 _multiplier) {
        (uint128 liquidity, address user, uint256 pid, ) = getUserPositionInfo(_tokenId);
        // Set default multiplier
        _multiplier = BOOST_PRECISION;
        // In order to save gas, no need to check the farms which have never beed boosted.
        if (everBoosted[pid]) {
            ItMap storage itmap = userInfo[user];
            uint256 prevMultiplier = itmap.data[_tokenId];
            if (prevMultiplier == 0) return BOOST_PRECISION;
            if (!whiteList[pid]) {
                if (itmap.contains(_tokenId)) {
                    itmap.remove(_tokenId);
                    emit DeactiveFarmPool(user, pid, _tokenId);
                }
            } else {
                _multiplier = _boostCalculate(user, pid, avgLockDuration(), uint256(liquidity));
                itmap.insert(_tokenId, _multiplier);
            }
            emit UpdatePoolBoostMultiplier(user, pid, _tokenId, prevMultiplier, _multiplier);
        }
    }

    /// @notice Remove user boost multiplier when user withdraw or butn in MasterChef V3.
    /// @param _user User address.
    /// @param _tokenId Token Id of position NFT.
    /// @param _pid Id of MasterChef V3 farm pool.
    function removeBoostMultiplier(address _user, uint256 _tokenId, uint256 _pid) external onlyMasterChefV3 {
        // In order to save gas, no need to check the farms which have never beed boosted.
        if (everBoosted[_pid]) {
            ItMap storage itmap = userInfo[_user];
            if (itmap.contains(_tokenId)) {
                itmap.remove(_tokenId);
                emit DeactiveFarmPool(_user, _pid, _tokenId);
            }
        }
    }

    /// @notice Active user farm pool.
    /// @param _tokenId Token Id of position NFT.
    function activate(uint256 _tokenId) external {
        (uint128 liquidity, address user, uint256 pid, ) = getUserPositionInfo(_tokenId);
        require(whiteList[pid], 'Not boosted farm pool');
        require(user == msg.sender, 'Not owner');
        ItMap storage itmap = userInfo[user];
        require(!itmap.contains(_tokenId), 'Already boosted');
        require(itmap.keys.length < MAX_BOOST_POSITION, 'Boosted positions reach to MAX');
        updateUserLockedAmount(user);

        _updateBoostMultiplier(itmap, user, pid, _tokenId, avgLockDuration(), uint256(liquidity));

        emit ActiveFarmPool(user, pid, _tokenId);
    }

    /// @notice Deactive user farm pool.
    /// @param _tokenId Token Id of position NFT.
    function deactive(uint256 _tokenId) external {
        ItMap storage itmap = userInfo[msg.sender];
        require(itmap.contains(_tokenId), 'None boost user');

        if (itmap.data[_tokenId] > BOOST_PRECISION) {
            MASTER_CHEF_V3.updateBoostMultiplier(_tokenId, BOOST_PRECISION);
        }
        itmap.remove(_tokenId);

        (, , uint256 pid, ) = getUserPositionInfo(_tokenId);
        emit DeactiveFarmPool(msg.sender, pid, _tokenId);
    }

    /// @param _user user address.
    /// @param _pid pool id.
    /// @param _tokenId token id.
    /// @param _duration cake pool average locked duration.
    /// @param _liquidity position liquidity.
    function _updateBoostMultiplier(
        ItMap storage itmap,
        address _user,
        uint256 _pid,
        uint256 _tokenId,
        uint256 _duration,
        uint256 _liquidity
    ) internal {
        // Used to be boost farm pool and current is not, remove from mapping
        if (!whiteList[_pid]) {
            if (itmap.data[_tokenId] > BOOST_PRECISION) {
                // reset to BOOST_PRECISION
                MASTER_CHEF_V3.updateBoostMultiplier(_tokenId, BOOST_PRECISION);
            }
            itmap.remove(_tokenId);
            emit DeactiveFarmPool(_user, _pid, _tokenId);
            return;
        }

        (, , , uint256 prevMultiplier) = getUserPositionInfo(_tokenId);
        uint256 multiplier = _boostCalculate(_user, _pid, _duration, _liquidity);

        if (multiplier < BOOST_PRECISION) {
            multiplier = BOOST_PRECISION;
        } else if (multiplier > MAX_BOOST_PRECISION) {
            multiplier = MAX_BOOST_PRECISION;
        }

        // Update multiplier to MCV3
        if (multiplier != prevMultiplier) {
            MASTER_CHEF_V3.updateBoostMultiplier(_tokenId, multiplier);
        }
        itmap.insert(_tokenId, multiplier);

        emit UpdatePoolBoostMultiplier(_user, _pid, _tokenId, prevMultiplier, multiplier);
    }

    /// @notice Whether position boosted specific farm pool.
    /// @param _tokenId Token Id of position NFT.
    function isBoostedPool(uint256 _tokenId) external view returns (bool, uint256) {
        (, address user, uint256 pid, ) = getUserPositionInfo(_tokenId);
        return (userInfo[user].contains(_tokenId), pid);
    }

    /// @notice Actived position list.
    /// @param _user user address.
    function activedPositions(address _user) external view returns (uint256[] memory positions) {
        ItMap storage itmap = userInfo[_user];
        if (itmap.keys.length == 0) return positions;

        positions = new uint256[](itmap.keys.length);
        // solidity for-loop not support multiple variables initializae by "," separate.
        for (uint256 index = 0; index < itmap.keys.length; index++) {
            positions[index] = itmap.keys[index];
        }
    }

    function getUserPositionInfo(
        uint256 _tokenId
    ) internal view returns (uint128 liquidity, address user, uint256 pid, uint256 boostMultiplier) {
        (liquidity, , , , , , user, pid, boostMultiplier) = MASTER_CHEF_V3.userPositionInfos(_tokenId);
    }

    /// @notice Anyone can call this function, if you find some guys effectived multiplier is not fair
    /// for other users, just call "updateLiquidity" function in MasterChef V3.
    /// @param _tokenId Token Id of position NFT.
    /// @dev If return value not in range [BOOST_PRECISION, MAX_BOOST_PRECISION]
    /// the actual effectived multiplier will be the close to side boundry value.
    function getUserMultiplier(uint256 _tokenId) external view returns (uint256) {
        (uint128 liquidity, address user, uint256 pid, ) = getUserPositionInfo(_tokenId);
        if (!whiteList[pid]) {
            return BOOST_PRECISION;
        } else {
            return _boostCalculate(user, pid, avgLockDuration(), uint256(liquidity));
        }
    }

    /// @notice Agni pool average locked duration calculator.
    function avgLockDuration() public view returns (uint256) {
        uint256 totalStakedAmount = IERC20(AGNI).balanceOf(AGNI_POOL);

        uint256 pricePerFullShare = IAgniPool(AGNI_POOL).getPricePerFullShare();

        uint256 flexibleShares;
        if (totalStakedAmount > totalLockedAmount && pricePerFullShare > 0)
            flexibleShares = ((totalStakedAmount - totalLockedAmount) * 1e18) / pricePerFullShare;
        if (flexibleShares == 0) return 0;

        uint256 originalShares = (totalLockedAmount * 1e18) / pricePerFullShare;
        if (originalShares == 0) return 0;

        uint256 boostedRatio = ((IAgniPool(AGNI_POOL).totalShares() - flexibleShares) * BOOST_RATIO_PRECISION) /
            originalShares;
        if (boostedRatio <= BOOST_RATIO_PRECISION) return 0;

        uint256 boostWeight = IAgniPool(AGNI_POOL).BOOST_WEIGHT();
        uint256 maxLockDuration = IAgniPool(AGNI_POOL).MAX_LOCK_DURATION() * BOOST_RATIO_PRECISION;

        uint256 duration = ((boostedRatio - BOOST_RATIO_PRECISION) * 365 * BOOST_WEIGHT_PRECISION) / boostWeight;
        return duration <= maxLockDuration ? duration : maxLockDuration;
    }

    /// @notice Get the total liquidity.
    /// @dev Will use the smaller value between MasterChefV3 pool totalLiquidity and V3 pool liquidity.
    /// @param _pid pool id(MasterchefV3 pool).
    function _getTotalLiquidity(uint256 _pid) internal view returns (uint256) {
        (, address v3Pool, , , , uint256 totalLiquidity, ) = MASTER_CHEF_V3.poolInfo(_pid);
        uint256 v3PoolLiquidity = IPancakeV3Pool(v3Pool).liquidity();
        if (totalLiquidity > v3PoolLiquidity) {
            totalLiquidity = v3PoolLiquidity;
        }
        return totalLiquidity;
    }

    /// @param _user user address.
    /// @param _pid pool id(MasterchefV3 pool).
    /// @param _duration cake pool average locked duration.
    /// @param _liquidity position liquidity.
    function _boostCalculate(
        address _user,
        uint256 _pid,
        uint256 _duration,
        uint256 _liquidity
    ) internal view returns (uint256) {
        if (_duration == 0) return BOOST_PRECISION;

        uint256 dB = (cA * _liquidity) / CA_PRECISION;
        // dB == 0 means _liquidity close to 0
        if (_liquidity == 0 || dB == 0) return BOOST_PRECISION;

        (, , , , uint256 lockStartTime, uint256 lockEndTime, , , uint256 userLockedAmount) = IAgniPool(AGNI_POOL)
            .userInfo(_user);
        if (userLockedAmount == 0 || block.timestamp >= lockEndTime) return BOOST_PRECISION;

        uint256 totalLiquidity = _getTotalLiquidity(_pid);

        uint256 userLockedDuration = (lockEndTime - lockStartTime) / (3600 * 24); // days

        // will use cBOverride[pid] If cBOverride[pid] is greater than 0 , or will use global cB.
        uint256 realCB = cBOverride[_pid] > 0 ? cBOverride[_pid] : cB;

        uint256 aB = (((totalLiquidity * userLockedAmount * userLockedDuration) *
            BOOST_RATIO_PRECISION *
            CB_PRECISION) / realCB) / (totalLockedAmount * _duration);

        // should "*" BOOST_PRECISION
        return ((_liquidity < (dB + aB) ? _liquidity : (dB + aB)) * BOOST_PRECISION) / dB;
    }
}