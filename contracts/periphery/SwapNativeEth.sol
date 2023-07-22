// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IPool} from "../interfaces/IPool.sol";
import {IController} from "../interfaces/IController.sol";
import {IPoolFactory} from "../interfaces/IPoolFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error DexSwapFailed();
error InvalidPool();

interface IUniversalRouter {
    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline) external payable;
}

contract SwapNativeEth is ReentrancyGuard {
  using SafeERC20 for IERC20;
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

    uint256[] memory amounts = new uint256[](swapData.length);
    for(uint i = 0; i < swapData.length; i++) {
      (,IPool.SwapDescription memory desc) = abi.decode(swapData[i][4:], (address, IPool.SwapDescription));
      (bool success, bytes memory returnData) = controller.getOneInch().call{value: desc.amount}(swapData[i]);

      if (!success) {
        revert DexSwapFailed();
      }
      (uint256 returnAmount,) = abi.decode(returnData, (uint256,uint256));
      amounts[i] = returnAmount;
      
      desc.dstToken.safeApprove(_pool, type(uint256).max);
    }

    IPool(_pool).deposit(amounts);
  }
}
