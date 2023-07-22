// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IController} from "./interfaces/IController.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

error TokenNotSupported();

contract StakeGardenPool is Ownable {
  using SafeERC20 for ERC20;

  mapping(address => uint256) public weights;

  // address public USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
  // address public WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
  address public oneInch = 0x1111111254EEB25477B68fb85Ed929f73A960582;

  string public name;
  string public symbol;
  address public immutable controller;
  //0x0e9465ba62abab0306cf729788220e07c6b55001
  constructor(
    string memory _name, 
    string memory _symbol, 
    address _controller, 
    address[] memory _stakeTokens
  ) onlyAllowedTokens(_controller, _stakeTokens) {
    // Set name and symbol
    name = _name;
    symbol = _symbol;
    controller = _controller;

    // Approving max for simplicity
    uint256 tokenCount = _stakeTokens.length;
    for (uint i = 0; i < tokenCount; i++) {
      IERC20(_stakeTokens[i]).safeApprove(oneInch, type(uint256).max);
    }
  }

  function swap(bytes calldata data) external onlyOwner {
    (bool success,) = oneInch.call(data);
    require(success, "Swap failed");
  }

  modifier onlyAllowedTokens(address _controller, address[] memory _stakeTokens) {
    uint256 tokenCount = _stakeTokens.length;
    for (uint i = 0; i < tokenCount; i++) {
      if (!IController(_controller).isTokenValid(_stakeTokens[i])) {
        revert TokenNotSupported();
      }
    }
    _;
  }
}
