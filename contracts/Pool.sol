// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IPool} from "./interfaces/IPool.sol";
import {IController} from "./interfaces/IController.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

error TokenNotSupported();
error TokenAndWeightsMismatch();
error AmountCountMismatch();
error InvalidZeroAmount();
error InsufficientBalance();

contract StakeGardenPool is Ownable, IPool, ERC20 {
  using SafeERC20 for IERC20;

  IController public immutable controller;

  address[] public stakeTokens;

  mapping(address => uint256) public weights;

  constructor(
    string memory _name, 
    string memory _symbol, 
    address _controller, 
    address[] memory _stakeTokens,
    uint256[] memory _weights
  ) ERC20(_name, _symbol) onlyAllowedTokens(_controller, _stakeTokens) {
    if (_stakeTokens.length != _weights.length) {
      revert TokenAndWeightsMismatch();
    }
    
    stakeTokens = _stakeTokens;
    controller = IController(_controller);
    
    uint256 tokenCount = _stakeTokens.length;
    for (uint256 i = 0; i < tokenCount; i++) {
      weights[_stakeTokens[i]] = _weights[i];

      // Approving max for simplicity
      IERC20(_stakeTokens[i]).safeApprove(controller.getOneInch(), type(uint256).max);
    }
  }

  function deposit(uint256[] memory amounts) external {
    address[] memory _stakeTokens = stakeTokens;
    uint256 tokenCount = _stakeTokens.length;
    if (amounts.length != tokenCount) {
      revert AmountCountMismatch();
    }
    
    uint256 poolShare = type(uint256).max;
    for (uint256 i = 0; i < tokenCount; i++) {
        uint256 amount = amounts[i];
        if (amount == 0) {
          revert InvalidZeroAmount();
        }

        IERC20(_stakeTokens[i]).safeTransferFrom(msg.sender, address(this), amount);

        uint256 tokenShare = (amount * 1e18) / weights[_stakeTokens[i]];
        if (tokenShare < poolShare) {
            poolShare = tokenShare;
        }
    }

    _mint(msg.sender, poolShare);
  }

  function withdraw(uint256 lpAmount) external {
    if (balanceOf(msg.sender) < lpAmount) {
      revert InsufficientBalance();
    }
    
    _burn(msg.sender, lpAmount);

    address[] memory _stakeTokens = stakeTokens;
    uint256 tokenCount = _stakeTokens.length;
    for (uint256 i = 0; i < tokenCount; i++) {
      uint256 assetAmount = (lpAmount * weights[_stakeTokens[i]]) / 1e18;
      IERC20(_stakeTokens[i]).safeTransfer(msg.sender, assetAmount);
    }
  }

  function _rebalance(uint256[] memory _weights) private {
    address[] memory _stakeTokens = stakeTokens;
    uint256 tokenCount = _stakeTokens.length;

    if (_stakeTokens.length != _weights.length) {
      revert TokenAndWeightsMismatch();
    }

    for (uint256 i = 0; i < tokenCount; i++) {
        weights[_stakeTokens[i]] = _weights[i];
    }
  }

  function swap(bytes calldata data) external onlyOwner {
    // @TODO: decode calldata to get token amounts
    // @TODO: call _rebalance to update weights
    (bool success,) = controller.getOneInch().call(data);
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
