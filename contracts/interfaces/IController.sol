// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IController {
  function setOneInch(address _oneInch) external;

  function setPoolFactory(address _poolFactory) external;

  function setTradeModule(address _tradeModule) external;

  function addAllowedStakeTokens(address[] calldata _tokens) external;

  function removeAllowedStakeTokens(address[] calldata _tokens) external;

  function getPoolFactory() external view returns (address);

  function getOneInch() external view returns (address);

  function getAllowedStakeTokens() external view returns (address[] memory);
  
  function isTokenValid(address _token) external view returns (bool);
}
