// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IController {
  function setPoolFactory(address _poolFactory) external;
  function setTradeModule(address _tradeModule) external;
  function addAllowedStakeTokens(address[] calldata _tokens) external;
  function removeAllowedStakeTokens(address[] calldata _tokens) external;
  function getAllowedStakeTokens() external view returns (address[] memory);
  function isTokenValid(address _token) external view returns (bool);
}
