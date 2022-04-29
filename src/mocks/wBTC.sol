// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";

contract WrapBitcoin is ERC20 {
    // solhint-disable-next-line
    constructor() ERC20("Wrapped Bitcoin", "wBTC") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
