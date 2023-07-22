// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Pool} from "./Pool.sol";
import {IPool} from "./interfaces/IPool.sol";
import {IPoolFactory} from "./interfaces/IPoolFactory.sol";

contract PoolFactory is IPoolFactory {

  event PoolCreated(address poolAddress, string name, string symbol, address controller);

  function createPool(
    address[] calldata stakeTokens,
    uint256[] calldata weights,
    string calldata name,
    string calldata symbol
  ) override external {
    // Please note, the weights array is not used in the Pool creation
    IPool pool = new Pool(name, symbol, msg.sender, stakeTokens);
    
    emit PoolCreated(address(pool), name, symbol, msg.sender);
  }
}