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
error DexSwapFailed();

contract StakeGardenPool is Ownable, IPool, ERC20 {
  using SafeERC20 for IERC20;

  event Deposit(uint256[] amounts);
  event Withdraw(uint256 amount);
  event Rebalance(uint256[] weights);

  IController public immutable controller;

  uint256 public totalWeight;
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
    
    uint256 length = _stakeTokens.length;
    for (uint256 i = 0; i < length; i++) {
      weights[_stakeTokens[i]] = _weights[i];
      totalWeight += _weights[i];

      // Approving max for simplicity
      IERC20(_stakeTokens[i]).safeApprove(controller.getOneInch(), type(uint256).max);
    }
  }

  function deposit(uint256[] memory amounts) external {
    address[] memory _stakeTokens = stakeTokens;
    uint256 length = _stakeTokens.length;
    if (amounts.length != length) {
      revert AmountCountMismatch();
    }
    
    uint256 poolShare = type(uint256).max;
    for (uint256 i = 0; i < length; i++) {
        uint256 amount = amounts[i];
        if (amount == 0) {
          revert InvalidZeroAmount();
        }

        uint256 tokenShare = (amount * 1e18) / weights[_stakeTokens[i]];
        if (tokenShare < poolShare) {
            poolShare = tokenShare;
        }
    }

    _mint(msg.sender, poolShare);
    emit Deposit(amounts);
  }

  function withdraw(uint256 lpAmount) external {
    if (balanceOf(msg.sender) < lpAmount) {
      revert InsufficientBalance();
    }
    
    _burn(msg.sender, lpAmount);

    address[] memory _stakeTokens = stakeTokens;
    uint256 length = _stakeTokens.length;
    for (uint256 i = 0; i < length; i++) {
      uint256 assetAmount = (lpAmount * weights[_stakeTokens[i]]) / 1e18;
      IERC20(_stakeTokens[i]).safeTransfer(msg.sender, assetAmount);
    }
    emit Withdraw(lpAmount);
  }

  function _rebalance(uint256[] memory _weights) private {
    address[] memory _stakeTokens = stakeTokens;
    uint256 length = _stakeTokens.length;

    if (_stakeTokens.length != _weights.length) {
      revert TokenAndWeightsMismatch();
    }

    for (uint256 i = 0; i < length; i++) {
        weights[_stakeTokens[i]] = _weights[i];
    }
  }

  function rebalance(bytes calldata data) external onlyOwner {
    (,SwapDescription memory desc) = abi.decode(data[4:], (address, SwapDescription));

    if (!isStakeToken(address(desc.srcToken)) || !isStakeToken(address(desc.dstToken))) {
      revert TokenNotSupported();
    }

    (bool success,) = controller.getOneInch().call(data);
    if (!success) {
      revert DexSwapFailed();
    }

    // Get current balance of tokens after the swap
    uint256 sellTokenBalance = desc.srcToken.balanceOf(address(this));
    uint256 buyTokenBalance = desc.dstToken.balanceOf(address(this));

    // Calculate new weights based on token balances
    weights[address(desc.srcToken)] = sellTokenBalance * totalWeight / (sellTokenBalance + buyTokenBalance);
    weights[address(desc.dstToken)] = totalWeight - weights[address(desc.srcToken)];

    uint256 count = stakeTokens.length;
    uint256[] memory _weights = new uint256[](count);

    for (uint256 i = 0; i < count; i++) {
      _weights[i] = weights[stakeTokens[i]];
    }
    
    _rebalance(_weights);
    emit Rebalance(_weights);
  }

  function isStakeToken(address token) private view returns (bool) {
    uint256 length = stakeTokens.length;

    for (uint256 i = 0; i < length; i++) {
      if (stakeTokens[i] == token) {
        return true;
      }
    }

    return false;
  }

  modifier onlyAllowedTokens(address _controller, address[] memory _stakeTokens) {
    uint256 length = _stakeTokens.length;

    for (uint i = 0; i < length; i++) {
      if (!IController(_controller).isTokenValid(_stakeTokens[i])) {
        revert TokenNotSupported();
      }
    }
    _;
  }
}
