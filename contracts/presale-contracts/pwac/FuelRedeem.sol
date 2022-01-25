// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./PFuelToken.sol";

contract FuelRedeem is Ownable, ReentrancyGuard {

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    PFuelToken public pfuel;
    address public fuelAddress;

    uint256 public startBlock;

    bool public hasBurnedUnsoldPresale = false;

    event fuelSwap(address sender, uint256 amount);
    event burnUnclaimedFuel(uint256 amount);
    event startBlockChanged(uint256 newStartBlock);

    constructor(uint256 _startBlock, address _pfuelAddress, address _fuelAddress) {
        require(_pfuelAddress != _fuelAddress, "pfuel cannot be equal to fuel");
        startBlock   = _startBlock;
        pfuel = PFuelToken(_pfuelAddress);
        fuelAddress  = _fuelAddress;
    }

    function swapPFuelForFuel(uint256 swapAmount) external nonReentrant {
        require(block.number >= startBlock, "fuel redemption hasn't started yet, good things come to those that wait ;)");
        require(IERC20(fuelAddress).balanceOf(address(this)) >= swapAmount, "Not Enough tokens in contract for swap");
        pfuel.transferFrom(msg.sender, BURN_ADDRESS, swapAmount);
        IERC20(fuelAddress).transfer(msg.sender, swapAmount);

        emit fuelSwap(msg.sender, swapAmount);
    }

    function sendUnclaimedFuelToDeadAddress() external onlyOwner {
        require(block.number > pfuel.endBlock(), "can only send excess fuel to dead address after presale has ended");
        require(!hasBurnedUnsoldPresale, "can only burn unsold presale once!");

        require(pfuel.pFuelRemaining() <= IERC20(fuelAddress).balanceOf(address(this)),
            "burning too much fuel, founders may need to top up");

        if (pfuel.pFuelRemaining() > 0)
            IERC20(fuelAddress).transfer(BURN_ADDRESS, pfuel.pFuelRemaining());
        hasBurnedUnsoldPresale = true;

        emit burnUnclaimedFuel(pfuel.pFuelRemaining());
    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if sale has already commenced");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;

        emit startBlockChanged(_newStartBlock);
    }
}