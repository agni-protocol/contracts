// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/SafeCast.sol";
import "./interfaces/IAgniPool.sol";
import "./interfaces/ILMPool.sol";
import "./interfaces/ILMPoolDeployer.sol";
import "./interfaces/IMasterChefV3.sol";
import "./interfaces/IFarmBooster.sol";
import "./interfaces/IWMNT.sol";
import "./utils/Multicall.sol";
import "./Enumerable.sol";

contract ExtraIncentivePool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

     struct PoolInfo {
        uint256 allocPoint;
        // V3 pool address
        IAgniPool pool;
    }

    /// @notice Address of incentive token.
    IERC20 public immutable incentiveToken;

    /// @notice Address of masterchef.
    IMasterChefV3 public immutable masterChef;

    /// @notice Address of Receiver contract.
    address public receiver;

    /// @notice Info of each MCV3 pool.
    mapping(address => PoolInfo) public poolInfos;
    // mapping(uint256 => PositonInfo) public positionInfos;


    /// @notice Total allocation points. Must be the sum of all pools' allocation points.
    uint256 public totalAllocPoint;

    uint256 public latestPeriodNumber;
    uint256 public latestPeriodStartTime;
    uint256 public latestPeriodEndTime;
    uint256 public latestPeriodIncentiveTokenPerSecond;

    /// @notice Record the incentive token amount belong to MasterChefV3.
    uint256 public incentiveAmountBelongToMC;

    uint256 public PERIOD_DURATION = 1 days;
    uint256 public constant MAX_DURATION = 30 days;
    uint256 public constant MIN_DURATION = 1 days;
    uint256 public constant PRECISION = 1e12;

    error InvalidPool();
    error ZeroAddress();
    error InvalidPeriodDuration();

    event AddPool(IAgniPool indexed pool, uint256 allocPoint);
    event SetPool(IAgniPool indexed pool, uint256 allocPoint);
    event NewReceiver(address receiver);
    event NewUpkeepPeriod(
        uint256 indexed periodNumber,
        uint256 startTime,
        uint256 endTime,
        uint256 agniPerSecond,
        uint256 agniAmount
    );
    event UpdateUpkeepPeriod(
        uint256 indexed periodNumber,
        uint256 oldEndTime,
        uint256 newEndTime,
        uint256 remainingAgni
    );
    event NewPeriodDuration(uint256 periodDuration);
    event Harvest(address indexed sender, address to, uint256 indexed tokenId, uint256 reward);

    modifier onlyValidPool(address _pool) {
        PoolInfo storage _poolInfo  = poolInfos[_pool];
        if (address(_poolInfo.pool)!= _pool) revert InvalidPool();
        _;
    }

    modifier onlyReceiver() {
        require(receiver == msg.sender, "Not receiver");
        _;
    }

    /// @param _incentiveToken The incentive token contract address.
    /// @param _masterChef The masterchef contract address.
    constructor(IERC20 _incentiveToken, IMasterChefV3 _masterChef) {
        incentiveToken = _incentiveToken;
        masterChef = _masterChef;
    }

    /// @notice Add a new pool. Can only be called by the owner.
    /// @notice One v3 pool can only create one pool.
    /// @param _allocPoint Number of allocation points for the new pool.
    /// @param _pool Address of the V3 pool.
    function add(IAgniPool _pool,uint256 _allocPoint) external onlyOwner {
        totalAllocPoint += _allocPoint;
       
        poolInfos[address(_pool)] = PoolInfo({
            allocPoint: _allocPoint,
            pool: _pool
        });

        emit AddPool( _pool,_allocPoint);
    }

    /// @notice Update the given pool's incentive token allocation point. Can only be called by the owner.
    /// @param _pool The address of the pool. See `poolInfos`.
    /// @param _allocPoint New number of allocation points for the pool.
    function set(IAgniPool _pool, uint256 _allocPoint) external onlyOwner onlyValidPool(address(_pool)) {
        PoolInfo storage pool = poolInfos[address(_pool)];
      
        totalAllocPoint = totalAllocPoint - pool.allocPoint + _allocPoint;
        pool.allocPoint = _allocPoint;
        emit SetPool(_pool, _allocPoint);
    }

    function setReceiver(address _receiver) external onlyOwner {
        if (_receiver == address(0)) revert ZeroAddress();
        if (incentiveToken.allowance(_receiver, address(this)) != type(uint256).max) revert();
        receiver = _receiver;
        emit NewReceiver(_receiver);
    }

    /// @notice View function for checking pending incentive token rewards.
    /// @dev The pending incentive token amount. The actual amount will happen whenever liquidity changes or harvest.
    /// @param _tokenId Token Id of NFT.
    /// @return reward Pending reward.
    function pendingIncentiveToken(uint256 _tokenId) external view returns (uint256 reward) {
        (uint256 positionLiquidity,  uint256 poolLiquidity) = masterChef.getLiquidityByTokenId(_tokenId);

        uint256 currTimestamp = block.timestamp;
        uint256 endTimestamp = latestPeriodEndTime;
        uint256 positionLastRewardTimestamp = masterChef.getLastRewardTimeTimeByTokenId(_tokenId);

        if (positionLiquidity > 0){
            address _pool = masterChef.getPoolByTokenId(_tokenId);
            PoolInfo storage pool = poolInfos[_pool];

            uint256 duration;
            if (endTimestamp > currTimestamp) {
                duration = currTimestamp - positionLastRewardTimestamp;
            } else if (endTimestamp > positionLastRewardTimestamp) {
                duration = endTimestamp - positionLastRewardTimestamp;
            }

           uint256 shouldReward =  duration * latestPeriodIncentiveTokenPerSecond / PRECISION;
           uint256 pointReward = shouldReward * pool.allocPoint / totalAllocPoint;
           reward = pointReward * positionLiquidity / poolLiquidity;
        }
    }


    /// @notice harvest incentive token from pool.
    /// @param _tokenId Token Id of NFT.
    /// @param _to Address to.
    /// @return reward incentive token reward.
    function harvest(uint256 _tokenId, address _to) external nonReentrant returns (uint256 reward) {
        require(_to != address(0),"invalid to address");
        reward = this.pendingIncentiveToken(_tokenId);
        if (reward > 0){
            _safeTransfer(_to, reward);
            emit Harvest(msg.sender, _to, _tokenId, reward);
        }
    }


    /// @notice Upkeep period.
    /// @param _amount The amount of incentive token injected.
    /// @param _duration The period duration.
    function upkeep(uint256 _amount, uint256 _duration) external onlyReceiver {
        // Transfer incentive token from receiver.
        incentiveToken.safeTransferFrom(receiver, address(this), _amount);
        // Update incentiveAmountBelongToMC
        unchecked {
            incentiveAmountBelongToMC += _amount;
        }

        uint256 duration = PERIOD_DURATION;
        // Only use the _duration when _duration is between MIN_DURATION and MAX_DURATION.
        if (_duration >= MIN_DURATION && _duration <= MAX_DURATION) duration = _duration;
        uint256 currentTime = block.timestamp;
        uint256 endTime = currentTime + duration;
        uint256 incenivePerSecond;
        uint256 inceniveAmount = _amount;
        if (latestPeriodEndTime > currentTime) {
            uint256 remainingAgni = ((latestPeriodEndTime - currentTime) * latestPeriodIncentiveTokenPerSecond) / PRECISION;
            emit UpdateUpkeepPeriod(latestPeriodNumber, latestPeriodEndTime, currentTime, remainingAgni);
            inceniveAmount += remainingAgni;
        }
        incenivePerSecond = (inceniveAmount * PRECISION) / duration;
        unchecked {
            latestPeriodNumber++;
            latestPeriodStartTime = currentTime + 1;
            latestPeriodEndTime = endTime;
            latestPeriodIncentiveTokenPerSecond = incenivePerSecond;
        }
        emit NewUpkeepPeriod(latestPeriodNumber, currentTime + 1, endTime, incenivePerSecond, inceniveAmount);
    }

   
    /// @notice Set period duration.
    /// @dev Callable by owner
    /// @param _periodDuration New period duration.
    function setPeriodDuration(uint256 _periodDuration) external onlyOwner {
        if (_periodDuration < MIN_DURATION || _periodDuration > MAX_DURATION) revert InvalidPeriodDuration();
        PERIOD_DURATION = _periodDuration;
        emit NewPeriodDuration(_periodDuration);
    }

    /// @notice Safe Transfer incentiveToken.
    /// @param _to The incentiveToken receiver address.
    /// @param _amount Transfer incentiveToken amounts.
    function _safeTransfer(address _to, uint256 _amount) internal {
        if (_amount > 0) {
            uint256 balance = incentiveToken.balanceOf(address(this));
            if (balance < _amount) {
                _amount = balance;
            }
            // Update incentiveAmountBelongToMC
            unchecked {
                if (incentiveAmountBelongToMC >= _amount) {
                    incentiveAmountBelongToMC -= _amount;
                } else {
                    incentiveAmountBelongToMC = balance - _amount;
                }
            }
            incentiveToken.safeTransfer(_to, _amount);
        }
    }
}