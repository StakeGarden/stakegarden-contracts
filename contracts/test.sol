// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PoolToken is ERC20 {
    constructor() ERC20("PoolToken", "PT") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

contract Pool {
    PoolToken public poolToken;
    address[] public tokens;
    mapping(address => uint256) public weights;

    constructor(address[] memory _tokens, uint256[] memory _weights) {
        require(_tokens.length == _weights.length, "tokens and weights length mismatch");
        poolToken = new PoolToken();
        tokens = _tokens;
        for (uint256 i = 0; i < _tokens.length; i++) {
            weights[_tokens[i]] = _weights[i];
        }
    }

    function deposit(uint256[] memory amounts) external {
        require(amounts.length == tokens.length, "amounts length mismatch");
        uint256 poolTokenAmount = type(uint256).max;
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amount = amounts[i];
            require(amount > 0, "amount must be greater than 0");
            IERC20 token = IERC20(tokens[i]);
            require(token.transferFrom(msg.sender, address(this), amount), "transferFrom failed");
            uint256 tokenPoolTokenAmount = (amount * 1e18) / weights[tokens[i]];
            if (tokenPoolTokenAmount < poolTokenAmount) {
                poolTokenAmount = tokenPoolTokenAmount;
            }
        }
        poolToken.mint(msg.sender, poolTokenAmount);
    }

    function withdraw(uint256 poolTokenAmount) external {
        require(poolToken.balanceOf(msg.sender) >= poolTokenAmount, "insufficient balance");
        poolToken.burn(msg.sender, poolTokenAmount);
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amount = (poolTokenAmount * weights[tokens[i]]) / 1e18;
            IERC20 token = IERC20(tokens[i]);
            require(token.transfer(msg.sender, amount), "transfer failed");
        }
    }

    function rebalance(uint256[] memory _weights) external {
        require(_weights.length == tokens.length, "weights length mismatch");
        for (uint256 i = 0; i < tokens.length; i++) {
            weights[tokens[i]] = _weights[i];
        }
    }
}
