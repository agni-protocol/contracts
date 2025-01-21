// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import './ISelfPermit.sol';
import './IMulticall.sol';
import './ISwapRouter.sol';
import './ISwapRouter.sol';
import '@agniswap/v2-core/contracts/interfaces/IAgniRouterV2.sol';


interface ISmartRouter is ISwapRouter, IAgniRouterV2,  IMulticall, ISelfPermit {

}
