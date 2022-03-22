// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/security/PausableUpgradeable.sol";
import "../interfaces/IGac.sol";

/**
Supply schedules are defined in terms of Epochs

Epoch {
    Total Mint
    Start time
    Duration
    End time (implicit)
}
*/
contract GlobalAccessControlManaged is PausableUpgradeable {
    IGac public gac;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");

    function __GlobalAccessControlManaged_init(address _globalAccessControl)
        public
        onlyInitializing
    {
        __Pausable_init_unchained();
        gac = IGac(_globalAccessControl);
    }

    // @dev only holders of the given role on the GAC can call
    modifier onlyRole(bytes32 role) {
        require(gac.hasRole(role, msg.sender), "invalid-caller-role");
        _;
    }

    // @dev only holders of the given role on the GAC can call, or a specified address
    // @dev used to faciliate extra contract-specific permissioned accounts
    modifier onlyRoleOrAddress(bytes32 role, address account) {
        require(gac.hasRole(role, msg.sender) || msg.sender == account, "invalid-caller-role-or-address");
        _;
    }

    /// @dev can be pausable by GAC or local flag
    modifier gacPausable() {
        require(gac.paused() == false, "global-paused");
        require(paused() == false, "local-paused");
        _;
    }

    function pause() external {
        require(gac.hasRole(PAUSER_ROLE, msg.sender));
        _pause();
    }

    function unpause() external {
        require(gac.hasRole(UNPAUSER_ROLE, msg.sender));
        _unpause();
    }
}
