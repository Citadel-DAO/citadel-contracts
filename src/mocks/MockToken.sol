// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract MockToken is ERC20Upgradeable {
    function initialize(
        string memory _name,
        string memory _symbol
    ) public initializer {
        __ERC20_init(_name, _symbol);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
