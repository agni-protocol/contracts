// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IAgniPool.sol";
import "./ILMPool.sol";

interface ILMPoolDeployer {
    function deploy(IAgniPool pool) external returns (ILMPool lmPool);
}
