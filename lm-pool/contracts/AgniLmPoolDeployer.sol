// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@agniswap/core/contracts/interfaces/IAgniFactory.sol';
import '@agniswap/periphery/contracts/interfaces/INonfungiblePositionManager.sol';

import './AgniLmPool.sol';

/// @dev This contract is for Master Chef to create a corresponding LmPool when
/// adding a new farming pool. As for why not just create LmPool inside the
/// Master Chef contract is merely due to the imcompatibility of the solidity
/// versions.
contract AgniLmPoolDeployer {
    address public immutable masterChef;

    modifier onlyMasterChef() {
        require(msg.sender == masterChef, "Not MC");
        _;
    }

    constructor(address _masterChef) {
        masterChef = _masterChef;
    }

    /// @dev Deploys a LmPool
    /// @param pool The contract address of the Agni pool
    function deploy(IAgniPool pool) external onlyMasterChef returns (IAgniLmPool lmPool) {
        lmPool = new AgniLmPool(address(pool), masterChef, uint32(block.timestamp));
        IAgniFactory(INonfungiblePositionManager(IMasterChefV3(masterChef).nonfungiblePositionManager()).factory()).setLmPool(address(pool), address(lmPool));
    }
}
