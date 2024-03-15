// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@5.0.2/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts@5.0.2/access/Ownable.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/extensions/ERC20Permit.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/// @custom:security-contact aielonapp@gmail.com
contract AIElonApp is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    address private constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // USDC address on Polygon
    address private feeRecipient = 0xd7CE581456187D70963472048625814E36E463c1;
    IUniswapV2Router02 private uniswapRouter;
    uint256 public constant MAX_SUPPLY = 1000000000 * 10 ** 18; // 1,000,000,000 tokens
    uint256 public constant INITIAL_SUPPLY = 500000000 * 10 ** 18; // 500,000,000 tokens
    uint256 private constant BUYER_FEE = 50; // 5%
    uint256 private constant SELLER_FEE = 50; // 5%
    string public constant tokenMetadata = "ipfs://bafybeib6owxj6pzqtkqf45ubbzw63zbfgliics3gm7utjjhis7iktii2fq";

    constructor(address initialOwner) ERC20("AI Elon", "AIELON") Ownable(initialOwner) ERC20Permit("AI Elon") {
        _mint(msg.sender, INITIAL_SUPPLY);
        uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds maximum supply");
        _mint(to, amount);
    }

    function transferWithFee(address recipient, uint256 amount) public returns (bool) {
        uint256 fee = (amount * BUYER_FEE) / 1000; // 5% fee
        uint256 amountAfterFee = amount - fee;
        uint256 liquidityFee = fee / 2;

        if (recipient != owner() && recipient != address(0) && recipient != address(this)) {
            uint256 maxWalletAmount = (totalSupply() - balanceOf(address(0)) - balanceOf(address(this))) / 10; // 10% of the circulating supply
            require(balanceOf(recipient) + amountAfterFee <= maxWalletAmount, "Exceeds maximum wallet token amount");
        }

        // Transfer fee to feeRecipient
        super._transfer(_msgSender(), feeRecipient, liquidityFee);

        // Add liquidity to the Uniswap pool
        super._transfer(_msgSender(), address(this), liquidityFee);
        addLiquidity(liquidityFee);

        // Transfer the remaining amount to the recipient
        super._transfer(_msgSender(), recipient, amountAfterFee);
        return true;
    }

    function addLiquidity(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of USDC
            path,
            address(this), // Tokens received will be added to the contract's balance
            block.timestamp
        );
    }

    // to receive funds from uniswapV2Router when swapping
    receive() external payable {}
}
