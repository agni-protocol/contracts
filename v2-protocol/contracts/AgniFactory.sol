// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;

import './interfaces/IAgniFactory.sol';
import './AgniPair.sol';

contract AgniFactory is IAgniFactory {
    bytes32 public constant override INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(AgniPair).creationCode));

    address public override feeTo;
    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'Agni: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Agni: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Agni: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(AgniPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IAgniPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'Agni: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override{
        require(msg.sender == feeToSetter, 'Agni: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
