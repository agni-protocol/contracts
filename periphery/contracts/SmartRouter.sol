// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import './SwapRouter.sol';
import './base/Multicall.sol';
import './base/PeripheryImmutableState.sol';
import './base/SelfPermit.sol';
import './interfaces/ISmartRouter.sol';
import '@agniswap/v2-core/contracts/AgniRouterV2.sol';

contract SmartRouter is
        ISmartRouter,
        SwapRouter,
        AgniRouterV2
{

    constructor(
        address _factoryV2,
        address _deployer,
        address _factoryV3,
        address _WMNT
    ) AgniRouterV2(_factoryV2, _WMNT) SwapRouter(_deployer, _factoryV3, _WMNT) {}

}
