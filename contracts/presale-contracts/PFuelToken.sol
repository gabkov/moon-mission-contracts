// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// PFuelToken
contract PFuelToken is ERC20('PRE-FUEL', 'PFUEL'), ReentrancyGuard, Ownable {

    address public constant feeAddress = 0xaEc43A98f2Ba215b23dCDd3ac5707959A3bf3E26;

    uint256 public salePriceE35 = 1666 * (10 ** 31);

    uint256 public constant pFuelMaximumSupply = 30 * (10 ** 3) * (10 ** 18);

    // We use a counter to defend against people sending pfuel back
    uint256 public pFuelRemaining = pFuelMaximumSupply;

    uint256 public constant maxPFuelPurchase = 600 * (10 ** 18);

  
    uint256 oneHourBsc = 1200;  // block number
    uint256 oneDayBsc = oneHourBsc * 24;
    uint256 threeDaysBsc = oneDayBsc * 3;

    uint256 public startBlock;
    uint256 public endBlock;

    mapping(address => uint256) public userPFuelTally;

    event pFuelPurchased(address sender, uint256 maticSpent, uint256 pFuelReceived);
    event startBlockChanged(uint256 newStartBlock, uint256 newEndBlock);
    event salePriceE35Changed(uint256 newSalePriceE5);

    constructor(uint256 _startBlock) {
        startBlock = _startBlock;
        endBlock   = _startBlock + threeDaysBsc;
        _mint(address(this), pFuelMaximumSupply);
    }

    function buyPFuel() external payable nonReentrant {
        require(block.number >= startBlock, "presale hasn't started yet, good things come to those that wait");
        require(block.number < endBlock, "presale has ended, come back next time!");
        require(pFuelRemaining > 0, "No more pfuel remaining! Come back next time!");
        require(IERC20(address(this)).balanceOf(address(this)) > 0, "No more pfuel left! Come back next time!");
        require(msg.value > 0, "not enough matic provided");
        require(msg.value <= 3e22, "too much matic provided");
        require(userPFuelTally[msg.sender] < maxPFuelPurchase, "user has already purchased too much pfuel");

        uint256 originalPFuelAmount = (msg.value * salePriceE35) / 1e35;

        uint256 pFuelPurchaseAmount = originalPFuelAmount;

        if (pFuelPurchaseAmount > maxPFuelPurchase)
            pFuelPurchaseAmount = maxPFuelPurchase;

        if ((userPFuelTally[msg.sender] + pFuelPurchaseAmount) > maxPFuelPurchase)
            pFuelPurchaseAmount = maxPFuelPurchase - userPFuelTally[msg.sender];

        // if we dont have enough left, give them the rest.
        if (pFuelRemaining < pFuelPurchaseAmount)
            pFuelPurchaseAmount = pFuelRemaining;

        require(pFuelPurchaseAmount > 0, "user cannot purchase 0 pfuel");

        // shouldn't be possible to fail these asserts.
        assert(pFuelPurchaseAmount <= pFuelRemaining);
        assert(pFuelPurchaseAmount <= IERC20(address(this)).balanceOf(address(this)));
        IERC20(address(this)).transfer(msg.sender, pFuelPurchaseAmount);
        pFuelRemaining = pFuelRemaining - pFuelPurchaseAmount;
        userPFuelTally[msg.sender] = userPFuelTally[msg.sender] + pFuelPurchaseAmount;

        uint256 maticSpent = msg.value;
        uint256 refundAmount = 0;
        if (pFuelPurchaseAmount < originalPFuelAmount) {
            // max pFuelPurchaseAmount = 6e20, max msg.value approx 3e22 (if 10c matic, worst case).
            // overfow check: 6e20 * 3e22 * 1e24 = 1.8e67 < type(uint256).max
            // Rounding errors by integer division, reduce magnitude of end result.
            // We accept any rounding error (tiny) as a reduction in PAYMENT, not refund.
            maticSpent = ((pFuelPurchaseAmount * msg.value * 1e24) / originalPFuelAmount) / 1e24;
            refundAmount = msg.value - maticSpent;
        }
        if (maticSpent > 0) {
            (bool success, ) = payable(address(feeAddress)).call{value: maticSpent}("");
            require(success, "failed to send matic to fee address");
        }
        if (refundAmount > 0) {
            (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
            require(success, "failed to send matic to customer address");
        }

        emit pFuelPurchased(msg.sender, maticSpent, pFuelPurchaseAmount);
    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if sale has already commenced");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;
        endBlock   = _newStartBlock + threeDaysBsc;

        emit startBlockChanged(_newStartBlock, endBlock);
    }

    function setSalePriceE35(uint256 _newSalePriceE35) external onlyOwner {
        require(block.number < startBlock - (oneHourBsc * 4), "cannot change price 4 hours before start block");
        require(_newSalePriceE35 >= 2 * (10 ** 33), "new price can't too low");
        require(_newSalePriceE35 <= 4 * (10 ** 34), "new price can't too high");
        salePriceE35 = _newSalePriceE35;

        emit salePriceE35Changed(salePriceE35);
    }
}