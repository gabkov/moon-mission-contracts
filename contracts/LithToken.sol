// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// FuelToken with Governance.
contract FuelToken is ERC20('FUEL', 'FUEL'), Ownable {

    constructor() {
        _mint(address(0xaEc43A98f2Ba215b23dCDd3ac5707959A3bf3E26), uint256(37500000000000000000000));
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}