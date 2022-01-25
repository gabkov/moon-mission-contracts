// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract PreFuelToken is ERC20('PreFuel', 'PFUEL'), ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address  constant presaleAddress = 0xaEc43A98f2Ba215b23dCDd3ac5707959A3bf3E26;
    
    IERC20 public BUSD;
    
    IERC20 preFuel = IERC20(address(this));

    uint256 public salePrice = 5;

    uint256 public constant preFuelMaximumSupply = 30000 * (10 ** 18); //30k

    uint256 public preFuelRemaining = preFuelMaximumSupply;
    
    uint256 public maxHardCap = 150000 * (10 ** 6); // 150k usdc

    uint256 public constant maxPreFuelPurchase = 600 * (10 ** 18); // 600 pre-fuel

    uint256 public startBlock;
    
    uint256 public endBlock;

    uint256 public constant presaleDuration = 179800; // 5 days aprox

    mapping(address => uint256) public userPreFuelTotally;

    event StartBlockChanged(uint256 newStartBlock, uint256 newEndBlock);
    event PreFuelPurchased(address sender, uint256 usdcSpent, uint256 preFuelReceived);

    constructor(uint256 _startBlock, address _busdAddress) {
        startBlock  = _startBlock;
        endBlock    = _startBlock + presaleDuration;
        BUSD = IERC20(_busdAddress);
        _mint(address(this), preFuelMaximumSupply);
    }

    function buyPreFuel(uint256 _usdcSpent) external nonReentrant {
        require(block.number >= startBlock, "presale hasn't started yet, good things come to those that wait");
        require(block.number < endBlock, "presale has ended, come back next time!");
        require(preFuelRemaining > 0, "No more PreFuel remains!");
        require(preFuel.balanceOf(address(this)) > 0, "No more PreFuel left!");
        require(_usdcSpent > 0, "not enough usdc provided");
        require(_usdcSpent <= maxHardCap, "PreFuel Presale hardcap reached");
        require(userPreFuelTotally[msg.sender] < maxPreFuelPurchase, "user has already purchased too much PreFuel");

        uint256 preFuelPurchaseAmount = (_usdcSpent * 1000000000000) / salePrice;

        // if we dont have enough left, give them the rest.
        if (preFuelRemaining < preFuelPurchaseAmount)
            preFuelPurchaseAmount = preFuelRemaining;

        require(preFuelPurchaseAmount > 0, "user cannot purchase 0 PreFuel");

        // shouldn't be possible to fail these asserts.
        assert(preFuelPurchaseAmount <= preFuelRemaining);
        assert(preFuelPurchaseAmount <= preFuel.balanceOf(address(this)));
        
        //send PreFuel to user
        preFuel.safeTransfer(msg.sender, preFuelPurchaseAmount);
        // send usdc to presale address
    	BUSD.safeTransferFrom(msg.sender, address(presaleAddress), _usdcSpent);

        preFuelRemaining = preFuelRemaining - preFuelPurchaseAmount;
        userPreFuelTotally[msg.sender] = userPreFuelTotally[msg.sender] + preFuelPurchaseAmount;

        emit PreFuelPurchased(msg.sender, _usdcSpent, preFuelPurchaseAmount);

    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if sale has already started");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;
        endBlock   = _newStartBlock + presaleDuration;

        emit StartBlockChanged(_newStartBlock, endBlock);
    }

}