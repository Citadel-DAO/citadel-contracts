// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "openzeppelin-contracts/proxy/beacon/UpgradeableBeacon.sol";
import "./lib/GlobalAccessControlManaged.sol";

contract KnightingRoundBeacon is GlobalAccessControlManaged {
    bytes32 public constant CONTRACT_GOVERNANCE_ROLE =
        keccak256("CONTRACT_GOVERNANCE_ROLE");

    UpgradeableBeacon immutable beacon;

    constructor(
        address _globalAccessControl,
        address _initKnightingRoundImplementation
    ) {
        __GlobalAccessControlManaged_init(_globalAccessControl);
        beacon = new UpgradeableBeacon(_initKnightingRoundImplementation);
    }

    function update(address _newKnightingRoundImplementation)
        public
        onlyRole(CONTRACT_GOVERNANCE_ROLE)
    {
        beacon.upgradeTo(_newKnightingRoundImplementation);
    }

    function implementation() public view returns (address) {
        return beacon.implementation();
    }
}
