// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./lib/GlobalAccessControlManaged.sol";
import "./lib/Executor.sol";

/**
    Avatar 
    Forwards calls from the owner

*/
contract Avatar is GlobalAccessControlManaged, OwnableUpgradeable, Executor {
    function initialize(address _globalAccessControl, address _owner)
        public
        initializer
    {
        __GlobalAccessControlManaged_init(_globalAccessControl);
        __Ownable_init_unchained();
        transferOwnership(_owner);
    }

    /**
     * @dev Make arbitrary Ethereum call
     * @param to Address to call
     * @param value ETH value
     * @param data TX data
     */
    function call(
        address to,
        uint256 value,
        bytes memory data
    ) external payable onlyOwner gacPausable returns (bool success) {
        return execute(to, value, data, false, gasleft());
    }
}
