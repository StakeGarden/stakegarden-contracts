// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IPoolFactory {
  function createPool(
    address[] calldata stakeTokens,
    uint256[] calldata weights,
    string calldata name,
    string calldata symbol
  ) external;
}
