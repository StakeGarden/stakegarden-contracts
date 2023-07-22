// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {StakeGardenPool} from "./Pool.sol";
import {IPool} from "./interfaces/IPool.sol";
import {IController} from "./interfaces/IController.sol";
import {IPoolFactory} from "./interfaces/IPoolFactory.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract StakeGardenPoolFactory is IPoolFactory {

  IController public immutable controller;

  event PoolCreated(address poolAddress, string name, string symbol, address controller, uint256[] weights);

  constructor(address _controller) {
    controller = IController(_controller);
  }

  function createPool(
    address[] calldata stakeTokens,
    uint256[] calldata weights,
    string calldata name,
    string calldata symbol
  ) override external returns(IPool) {
    IPool pool = new StakeGardenPool(name, symbol, address(controller), stakeTokens, weights);
    Ownable(address(pool)).transferOwnership(msg.sender);

    emit PoolCreated(address(pool), name, symbol, address(controller), weights);
    return pool;
  }
}
