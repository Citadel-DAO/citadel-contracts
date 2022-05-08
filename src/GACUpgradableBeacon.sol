// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./lib/GlobalAccessControlManaged.sol";
import "openzeppelin-contracts/proxy/beacon/IBeacon.sol";
import "openzeppelin-contracts/utils/Address.sol";

/**
 * @dev This is a version of UpgradeableBeacon that works with the citadel GAC
 */
contract GACUpgradableBeacon is GlobalAccessControlManaged, IBeacon {
    bytes32 public constant CONTRACT_GOVERNANCE_ROLE =
        keccak256("CONTRACT_GOVERNANCE_ROLE");

    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address _globalAccessControl, address implementation_) {
        __GlobalAccessControlManaged_init(_globalAccessControl);

        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation)
        public
        virtual
        onlyRole(CONTRACT_GOVERNANCE_ROLE)
    {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(
            Address.isContract(newImplementation),
            "UpgradeableBeacon: implementation is not a contract"
        );
        _implementation = newImplementation;
    }
}
