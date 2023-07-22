// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IPool} from "../interfaces/IPool.sol";
import {IController} from "../interfaces/IController.sol";
import {IPoolFactory} from "../interfaces/IPoolFactory.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error DexSwapFailed();
error InvalidPool();

contract SwapNativeEth is ReentrancyGuard {
    IController public controller;

    constructor(address _controller) {
        controller = IController(_controller);
    }

    // @TODO: verify swapData/token ordering against pool.stakeTokens
    // @TODO: verify swapData.length = pool.stakeTokens.length
    function executeSwaps(address _pool, bytes[] calldata swapData) external payable nonReentrant {
      IPoolFactory factory = IPoolFactory(controller.getPoolFactory());
      
      if (!factory.isPool(_pool)) {
        revert InvalidPool();
      }

    uint256[] memory amounts;
      for(uint i = 0; i < swapData.length; i++) {
        (bool success, bytes memory returnData) = controller.getOneInch().call(swapData[i]);
        if (!success) {
          revert DexSwapFailed();
        }
        (uint256 returnAmount) = abi.decode(returnData, (uint256));
        amounts[i] = returnAmount;
      }

      IPool(_pool).deposit(amounts);
    }
}
