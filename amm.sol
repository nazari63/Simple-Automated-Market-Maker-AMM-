// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleAMM is Ownable {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    event Swap(address indexed sender, uint256 amountIn, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    // Provide liquidity to the pool
    function provideLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(tokenA.transferFrom(msg.sender, address(this), amountA), "Transfer of token A failed");
        require(tokenB.transferFrom(msg.sender, address(this), amountB), "Transfer of token B failed");

        reserveA += amountA;
        reserveB += amountB;
    }

    // Swap Token A for Token B
    function swapAForB(uint256 amountA) external {
        require(amountA > 0, "Amount must be greater than 0");
        uint256 amountB = getSwapAmount(amountA, reserveA, reserveB);
        require(amountB <= reserveB, "Not enough liquidity for swap");

        require(tokenA.transferFrom(msg.sender, address(this), amountA), "Transfer of token A failed");
        require(tokenB.transfer(msg.sender, amountB), "Transfer of token B failed");

        reserveA += amountA;
        reserveB -= amountB;

        emit Swap(msg.sender, amountA, amountB);
    }

    // Swap Token B for Token A
    function swapBForA(uint256 amountB) external {
        require(amountB > 0, "Amount must be greater than 0");
        uint256 amountA = getSwapAmount(amountB, reserveB, reserveA);
        require(amountA <= reserveA, "Not enough liquidity for swap");

        require(tokenB.transferFrom(msg.sender, address(this), amountB), "Transfer of token B failed");
        require(tokenA.transfer(msg.sender, amountA), "Transfer of token A failed");

        reserveB += amountB;
        reserveA -= amountA;

        emit Swap(msg.sender, amountB, amountA);
    }

    // Get swap amount based on reserves
    function getSwapAmount(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 997; // Applying 0.3% fee
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        return numerator / denominator;
    }

    // Withdraw liquidity
    function withdrawLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA <= reserveA && amountB <= reserveB, "Insufficient liquidity");

        reserveA -= amountA;
        reserveB -= amountB;

        require(tokenA.transfer(msg.sender, amountA), "Transfer of token A failed");
        require(tokenB.transfer(msg.sender, amountB), "Transfer of token B failed");
    }

    // Get reserves of the pool
    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }
}