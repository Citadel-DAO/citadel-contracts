// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {MerkleProofUpgradeable} from "openzeppelin-contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

import "./lib/GlobalAccessControlManaged.sol";

/**
 * @notice A basic guest list contract for testing.
 * @dev For a Vyper implementation of this contract containing additional
 * functionality, see https://github.com/banteg/guest-list/blob/master/contracts/GuestList.vy
 * The owner can invite arbitrary guests
 * A guest can be added permissionlessly with proof of inclusion in current merkle set
 * The owner can change the merkle root at any time
 * Merkle-based permission that has been claimed cannot be revoked permissionlessly.
 * Any guests can be revoked by the owner at-will
 * A guest list that gates access by merkle root
 * @notice authorized function to ignore merkle proof for testing, inspiration from yearn's approach to testing guestlist https://github.com/yearn/yearn-devdocs/blob/4664fdef7d10f3a767fa651975059c44cf1cdb37/docs/developers/v2/smart-contracts/test/TestGuestList.md
 */
contract KnightingRoundGuestlist is GlobalAccessControlManaged {
    bytes32 public constant TECH_OPERATIONS_ROLE =
        keccak256("TECH_OPERATIONS_ROLE");

    bytes32 public guestRoot;
    mapping(address => bool) public guests;

    event ProveInvitation(address indexed account, bytes32 indexed guestRoot);
    event SetGuestRoot(bytes32 indexed guestRoot);

    /**
     * @notice Create the test guest list, setting the message sender as
     * `owner`.
     * @dev Note that since this is just for testing, you're unable to change
     * `owner`.
     */
    function initialize(address _globalAccessControl) public initializer {
        __GlobalAccessControlManaged_init(_globalAccessControl);
    }

    /**
     * @notice Invite guests or kick them from the party.
     * @param _guests The guests to add or update.
     * @param _invited A flag for each guest at the matching index, inviting or
     * uninviting the guest.
     */
    function setGuests(address[] calldata _guests, bool[] calldata _invited) external onlyRole(TECH_OPERATIONS_ROLE) {
        _setGuests(_guests, _invited);
    }

    /**
     * @notice Permissionly prove an address is included in the current merkle root, thereby granting access
     * @notice Note that the list is designed to ONLY EXPAND in future instances
     * @notice The admin does retain the ability to ban individual addresses
     */
    function proveInvitation(address account, bytes32[] calldata merkleProof) public {
        // Verify Merkle Proof
        require(_verifyInvitationProof(account, merkleProof));

        address[] memory accounts = new address[](1);
        bool[] memory invited = new bool[](1);

        accounts[0] = account;
        invited[0] = true;

        _setGuests(accounts, invited);

        emit ProveInvitation(account, guestRoot);
    }

    /**
     * @notice Set the merkle root to verify invitation proofs against.
     * @notice Note that accounts not included in the root will still be invited if their inviation was previously approved.
     * @notice Setting to 0 removes proof verification versus the root, opening access
     */
    function setGuestRoot(bytes32 guestRoot_) external onlyRole(TECH_OPERATIONS_ROLE) {
        guestRoot = guestRoot_;

        emit SetGuestRoot(guestRoot);
    }

    /**
     * @notice Check if a guest with a bag of a certain size is allowed into
     * the party.
     * @param _guest The guest's address to check.
     */
    function authorized(
        address _guest,
        bytes32[] calldata _merkleProof
    ) external view returns (bool) {
        // Yes: If the user is on the list
        // No: If the user is not on the list
        bool invited = guests[_guest] || _verifyInvitationProof(_guest, _merkleProof);

        // If the user was previously invited, or proved invitiation via list, verify if the amount to deposit keeps them under the cap
        if (invited) {
            return true;
        } else {
            return false;
        }
    }

    function _setGuests(address[] memory _guests, bool[] memory _invited) internal {
        require(_guests.length == _invited.length);
        for (uint256 i = 0; i < _guests.length; i++) {
            if (_guests[i] == address(0)) {
                break;
            }
            guests[_guests[i]] = _invited[i];
        }
    }

    function _verifyInvitationProof(address account, bytes32[] calldata merkleProof) internal view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(account));
        return MerkleProofUpgradeable.verify(merkleProof, guestRoot, node);
    }
}