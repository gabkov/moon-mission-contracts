// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// LithToken with Governance.
contract LithToken is ERC20('LITHIUM', 'LITHIUM'), Ownable {

    constructor() {
        _mint(address(0x3a1D1114269d7a786C154FE5278bF5b1e3e20d31), uint256(37500000000000000000000));
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}