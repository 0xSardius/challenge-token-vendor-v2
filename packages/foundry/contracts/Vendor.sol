pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    /////////////////
    /// Errors //////
    /////////////////

    error InvalidEthAmount();
    error InsufficientVendorTokenBalance(uint256 available, uint256 requestedAmount);
    error EthTransferFailed(address to, uint256 amount);
    error InvalidTokenAmount();
    error InsufficientVendorEthBalance(uint256 vendorBalance, uint256 requestedAmount);

    //////////////////////
    /// State Variables //
    //////////////////////

    YourToken public immutable yourToken;
    uint256 public constant tokensPerEth = 100;

    ////////////////
    /// Events /////
    ////////////////

    event BuyTokens(address indexed buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address indexed seller, uint256 amountOfTokens, uint256 amountOfETH);

    ///////////////////
    /// Constructor ///
    ///////////////////

    constructor(address tokenAddress) Ownable(msg.sender) {
        yourToken = YourToken(tokenAddress);
    }

    ///////////////////
    /// Functions /////
    ///////////////////

    function buyTokens() external payable {
        if (msg.value == 0) revert InvalidEthAmount();
        uint256 amountOfTokens = msg.value * tokensPerEth;
        if (yourToken.balanceOf(address(this)) < amountOfTokens) revert InsufficientVendorTokenBalance(yourToken.balanceOf(address(this)), amountOfTokens);
        yourToken.transfer(msg.sender, amountOfTokens);
        emit BuyTokens(msg.sender, msg.value, amountOfTokens);

     }

    function withdraw() public onlyOwner { 
        // Send all ETH to owner using call
        uint256 ownerAmount = address(this).balance; 
        (bool success, ) = owner().call{value: ownerAmount}("");
        if (!success) revert EthTransferFailed(owner(), ownerAmount);

    }

    function sellTokens(uint256 amount) public {
        if (amount == 0) revert InvalidTokenAmount();
        uint256 amountOfETH = amount / tokensPerEth;
        if (address(this).balance < amountOfETH) revert InsufficientVendorEthBalance(address(this).balance, amountOfETH);
        yourToken.transferFrom(msg.sender, address(this), amount);
        (bool success, ) = msg.sender.call{value: amountOfETH}("");
        if (!success) revert EthTransferFailed(msg.sender, amountOfETH);
        emit SellTokens(msg.sender, amount, amountOfETH);
     }
}
