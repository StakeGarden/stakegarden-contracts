// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract StakeGardenController is Ownable {
  // Address of the pool factory
  address public poolFactory;

  // List of allowed liquid staking tokens
  address[] private allowedStakeTokens;

  // One Inch Address - 0x1111111254EEB25477B68fb85Ed929f73A960582
  address private oneInch;

  constructor(address _oneInch, address[] memory _allowedStakeTokens) {
    oneInch = _oneInch;
    allowedStakeTokens = _allowedStakeTokens;
  }

  function getOneInch() external view returns (address) {
    return oneInch;
  }

  function setOneInch(address _oneInch) external onlyOwner {
    oneInch = _oneInch;
  }

  // Sets a new address for the pool factory. Can only be called by the contract owner.
  function setPoolFactory(address _poolFactory) external onlyOwner {
    poolFactory = _poolFactory;
  }
  
  // Adds a list of new tokens to the list of allowed staking tokens. Can only be called by the contract owner.
  // _tokens: array of token addresses to be added
  function addAllowedStakeTokens(address[] calldata _tokens) external onlyOwner {
    for (uint i = 0; i < _tokens.length; i++) {
      allowedStakeTokens.push(_tokens[i]);
    }
  }

  // Returns the full list of allowed staking tokens
  function getAllowedStakeTokens() external view returns (address[] memory) {
      return allowedStakeTokens;
  }

  // Checks if a token is allowed
  function isTokenValid(address _token) external view returns (bool) {
    for (uint i = 0; i < allowedStakeTokens.length; i++) {
      if (allowedStakeTokens[i] == _token) {
        return true;
      }
    }
    return false;
  }

  // Removes a list of tokens from the list of allowed stake tokens. Can only be called by the contract owner.
  // _tokens: array of token addresses to be removed
  // Note: this function assumes there are no duplicates in allowedStakeTokens
  function removeAllowedStakeTokens(address[] calldata _tokens) external onlyOwner {
    for (uint i = 0; i < _tokens.length; i++) {
      for (uint j = 0; j < allowedStakeTokens.length; j++) {
        if (allowedStakeTokens[j] == _tokens[i]) {
          // Move the last token into the place of the one to delete,
          // then delete the last slot (same as pop())
          allowedStakeTokens[j] = allowedStakeTokens[allowedStakeTokens.length - 1];
          allowedStakeTokens.pop();
          break;
        }
      }
    }
  }
}
