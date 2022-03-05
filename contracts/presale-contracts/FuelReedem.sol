// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./PreFuelToken.sol";

contract FuelReedem is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    PreFuelToken public preFuelToken;

    IERC20 public fuelToken;

    address fuelAddress;

    bool  hasBurnedUnsoldPresale;

    bool  redeemState;

    uint256 public startBlock;

    event PreFuelToFuel(address sender, uint256 amount);
    event burnUnclaimedFuel(uint256 amount);
    event startBlockChanged(uint256 newStartBlock);

    constructor(uint256 _startBlock, address _preFuelAddress, address _fuelAddress) {
        require(_preFuelAddress != _fuelAddress, "prefuel cannot be equal to fuel");
        startBlock = _startBlock;
        preFuelToken = PreFuelToken(_preFuelAddress);
        fuelToken = IERC20(_fuelAddress);
    }

    function swapPreFuelForFuel() external nonReentrant {
        require(block.number >= startBlock, "fuel redemption hasn't started yet");

        uint256 swapAmount = preFuelToken.balanceOf(msg.sender);
        require(fuelToken.balanceOf(address(this)) >= swapAmount, "Not Enough tokens in contract for swap");
        require(preFuelToken.transferFrom(msg.sender, BURN_ADDRESS, swapAmount), "failed sending prefuel" );
        fuelToken.safeTransfer(msg.sender, swapAmount);

        emit PreFuelToFuel(msg.sender, swapAmount);
    }

    function sendUnclaimedFuelToDeadAddress() external onlyOwner {
        require(block.number > preFuelToken.endBlock(), "can only send excess fuel to dead address after presale has ended");
        require(!hasBurnedUnsoldPresale, "can only burn unsold presale once!");

        require(preFuelToken.preFuelRemaining() <= fuelToken.balanceOf(address(this)),
            "burning too much fuel, check again please");

        if (preFuelToken.preFuelRemaining() > 0)
            fuelToken.safeTransfer(BURN_ADDRESS, preFuelToken.preFuelRemaining());
        hasBurnedUnsoldPresale = true;

        emit burnUnclaimedFuel(preFuelToken.preFuelRemaining());
    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if presale has already commenced");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;

        emit startBlockChanged(_newStartBlock);
    }

}