// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import './SwapRouter.sol';
import './base/Multicall.sol';
import './base/SelfPermit.sol';
import './interfaces/ISmartRouter.sol';
import './AgniRouterV2.sol';
import './AgniRouterV3.sol';
import './base/PeripheryImmutableState.sol';
import './base/ImmutableState.sol';

contract SmartRouter is
        ISmartRouter,
        AgniRouterV3,
        AgniRouterV2,
        Multicall,
        SelfPermit
{

    constructor(
        address _factoryV2,
        address _deployer,
        address _factoryV3,
        address _WMNT
    ) ImmutableState(_factoryV2) PeripheryImmutableState(_deployer, _factoryV3, _WMNT) {}

}
