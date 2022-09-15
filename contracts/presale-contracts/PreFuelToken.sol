// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract PreFuelToken is ERC20('PreFuel', 'PFUEL'), ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address constant presaleAddress = 0xE936dAf67f6C33997CC695Ce6bd8eA2e141A1041; // test-acc2
    
    IERC20 public BUSD = IERC20(0x92325A71cdacf88E45aD12597EE59E662342D03a);
    
    IERC20 preFuel = IERC20(address(this));

    uint256 public salePrice = 5 * 1e18; // 5 BUSD

    uint256 public constant preFuelMaximumSupply = 30000 * 1e18; //30k

    uint256 public preFuelRemaining = preFuelMaximumSupply;
    
    uint256 public maxBusdAmount = 3000 * 1e18; // 3000 BUSD

    uint256 public constant maxPreFuelPurchase = 600 * 1e18; // 600 pre-fuel

    uint256 public startBlock;
    
    uint256 public endBlock;

    uint256 public constant presaleDuration = 57600; // 2 days aprox

    mapping(address => uint256) public userPreFuelTotally;

    event StartBlockChanged(uint256 newStartBlock, uint256 newEndBlock);
    event PreFuelPurchased(address sender, uint256 usdcSpent, uint256 preFuelReceived);

    constructor(uint256 _startBlock) {
        startBlock  = _startBlock;
        endBlock    = _startBlock + presaleDuration;
        _mint(address(this), preFuelMaximumSupply);
    }

    function buyPreFuel(uint256 _busdSpent) external nonReentrant {
        require(block.number >= startBlock, "presale hasn't started yet, good things come to those that wait");
        require(block.number < endBlock, "presale has ended, come back next time!");
        require(preFuelRemaining > 0, "No more PreFuel remains!");
        require(preFuel.balanceOf(address(this)) > 0, "No more PreFuel left!");
        require(_busdSpent > 0, "not enough BUSD provided");
        require(_busdSpent <= maxBusdAmount, "too much BUSD provided");
        require(userPreFuelTotally[msg.sender] < maxPreFuelPurchase, "user has already purchased too much PreFuel");

        uint256 originalPreFuelAmount = (_busdSpent / salePrice) * 1e18;

        uint256 preFuelPurchaseAmount = originalPreFuelAmount;

        if (preFuelPurchaseAmount > maxPreFuelPurchase){
            preFuelPurchaseAmount = maxPreFuelPurchase;
        }

        if ((userPreFuelTotally[msg.sender] + preFuelPurchaseAmount) > maxPreFuelPurchase){
            preFuelPurchaseAmount = maxPreFuelPurchase - userPreFuelTotally[msg.sender];
        }
        
        // if we dont have enough left, give them the rest.
        if (preFuelRemaining < preFuelPurchaseAmount){
            preFuelPurchaseAmount = preFuelRemaining;
        }

        require(preFuelPurchaseAmount > 0, "user cannot purchase 0 PreFuel");

        // shouldn't be possible to fail these asserts.
        assert(preFuelPurchaseAmount <= preFuelRemaining);
        assert(preFuelPurchaseAmount <= preFuel.balanceOf(address(this)));
        
        //send PreFuel to user
        preFuel.safeTransfer(msg.sender, preFuelPurchaseAmount);
        // send usdc to presale address
    	BUSD.safeTransferFrom(msg.sender, address(presaleAddress), _busdSpent);

        preFuelRemaining = preFuelRemaining - preFuelPurchaseAmount;
        userPreFuelTotally[msg.sender] = userPreFuelTotally[msg.sender] + preFuelPurchaseAmount;

        emit PreFuelPurchased(msg.sender, _busdSpent, preFuelPurchaseAmount);

    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if sale has already started");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;
        endBlock   = _newStartBlock + presaleDuration;

        emit StartBlockChanged(_newStartBlock, endBlock);
    }

}