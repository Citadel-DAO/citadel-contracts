// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "ds-test/test.sol";

import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {MathUpgradeable} from "openzeppelin-contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {AddressUpgradeable} from "openzeppelin-contracts-upgradeable/utils/AddressUpgradeable.sol";
import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/security/PausableUpgradeable.sol";
import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {IVault} from "./interfaces/badger/IVault.sol";
import "./lib/GlobalAccessControlManaged.sol";

/// @notice Handles supply schedules for citadel token.
/// @dev Supply schedules are defined in terms of Epochs.

contract SupplySchedule is GlobalAccessControlManaged, DSTest {
    bytes32 public constant CONTRACT_GOVERNANCE_ROLE =
        keccak256("CONTRACT_GOVERNANCE_ROLE");

    uint256 public constant epochLength = 21 days;
    uint256 public globalStartTimestamp;

    /// epoch index * epoch length = start time

    mapping(uint256 => uint256) public epochRate;

    /// ==================
    /// ===== Events =====
    /// ==================

    event MintingStartTimeSet(uint256 globalStartTimestamp);
    event EpochSupplyRateSet(uint256 epoch, uint256 rate);

    /// =======================
    /// ===== Initializer =====
    /// =======================

    function initialize(address _gac) public initializer {
        require(_gac != address(0), "address 0 invalid");
        __GlobalAccessControlManaged_init(_gac);
    }

    /// =======================
    /// ===== Public view =====
    /// =======================

    /// @notice finds epoch at a particular timestamp
    /// @param _timestamp at which the epoch needs to be calculated
    function getEpochAtTimestamp(uint256 _timestamp)
        public
        view
        returns (uint256)
    {
        require(
            globalStartTimestamp > 0,
            "SupplySchedule: minting not started"
        );
        return (_timestamp - globalStartTimestamp) / epochLength;
    }

    /// @notice finds epoch number at current timestamp
    function getCurrentEpoch() public view returns (uint256) {
        return getEpochAtTimestamp(block.timestamp);
    }

    /// @notice calculates the amount of mintable citadel for a particular epoch
    /// @param _epoch the epoch for which the mintable amount is calculated
    function getEmissionsForEpoch(uint256 _epoch)
        public
        view
        returns (uint256)
    {
        return epochRate[_epoch] * epochLength;
    }

    /// @notice calculates the amount of mintable citadel for current epoch
    function getEmissionsForCurrentEpoch() public view returns (uint256) {
        uint256 epoch = getCurrentEpoch();
        return getEmissionsForEpoch(epoch);
    }

    /// @notice calculates the citadel amount to mint since last mint time stamp
    /// @param lastMintTimestamp is the last timestamp when citadel was minted.
    /// @return mintable citadel amount
    function getMintable(uint256 lastMintTimestamp)
        external
        view
        returns (uint256)
    {
        uint256 cachedGlobalStartTimestamp = globalStartTimestamp;
        require(
            cachedGlobalStartTimestamp > 0,
            "SupplySchedule: minting not started"
        );
        require(
            block.timestamp > lastMintTimestamp,
            "SupplySchedule: already minted up to current block"
        );

        if (lastMintTimestamp < cachedGlobalStartTimestamp) {
            lastMintTimestamp = cachedGlobalStartTimestamp;
        }

        uint256 mintable = 0;

        uint256 startingEpoch = (lastMintTimestamp -
            cachedGlobalStartTimestamp) / epochLength;

        uint256 endingEpoch = (block.timestamp - cachedGlobalStartTimestamp) /
            epochLength;

        for (
            uint256 i = startingEpoch;
            i <= endingEpoch; /** See below ++i */

        ) {
            uint256 rate = epochRate[i];

            uint256 epochStartTime = cachedGlobalStartTimestamp +
                i *
                epochLength;
            uint256 epochEndTime = cachedGlobalStartTimestamp +
                (i + 1) *
                epochLength;

            uint256 time = MathUpgradeable.min(block.timestamp, epochEndTime) -
                MathUpgradeable.max(lastMintTimestamp, epochStartTime);

            mintable += rate * time;

            unchecked {
                ++i;
            }
        }

        return mintable;
    }

    /// ==============================
    /// ===== Governance actions =====
    /// ==============================

    /// @notice sets the minting start time.
    /// @param _globalStartTimestamp start time will be set to this.
    function setMintingStart(uint256 _globalStartTimestamp)
        external
        onlyRole(CONTRACT_GOVERNANCE_ROLE)
        gacPausable
    {
        require(
            globalStartTimestamp == 0,
            "SupplySchedule: minting already started"
        );
        require(
            _globalStartTimestamp >= block.timestamp,
            "SupplySchedule: minting must start at or after current time"
        );

        globalStartTimestamp = _globalStartTimestamp;
        emit MintingStartTimeSet(_globalStartTimestamp);
    }

    /// @notice sets epoch rate for a particular epoch
    /// @param _epoch is the epoch number
    /// @param _rate is the rate to set for epoch number _epoch
    function setEpochRate(uint256 _epoch, uint256 _rate)
        external
        onlyRole(CONTRACT_GOVERNANCE_ROLE)
        gacPausable
    {
        require(
            epochRate[_epoch] == 0,
            "SupplySchedule: rate already set for given epoch"
        );
        // TODO: Require this epoch is in the future. What happens if no data is set? (It just fails to mint until set)
        epochRate[_epoch] = _rate;
        emit EpochSupplyRateSet(_epoch, _rate);
    }
}
