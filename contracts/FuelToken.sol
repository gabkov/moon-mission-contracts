// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// FuelToken with Governance.
contract FuelToken is ERC20('FUEL', 'FUEL'), Ownable {

    constructor() {
        _mint(address(0xdEF7820104Ce56395372849859d15E33d46F9FcD), uint256(37500000000000000000000));
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}