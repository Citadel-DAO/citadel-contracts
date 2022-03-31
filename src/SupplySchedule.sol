// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "ds-test/test.sol";

import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {MathUpgradeable} from "openzeppelin-contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {SafeMathUpgradeable} from "openzeppelin-contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {AddressUpgradeable} from "openzeppelin-contracts-upgradeable/utils/AddressUpgradeable.sol";
import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/security/PausableUpgradeable.sol";
import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {IVault} from "./interfaces/badger/IVault.sol";
import "./lib/GlobalAccessControlManaged.sol";

/**
Supply schedules are defined in terms of Epochs

*/
contract SupplySchedule is GlobalAccessControlManaged, DSTest {
    bytes32 public constant CONTRACT_GOVERNANCE_ROLE = keccak256("CONTRACT_GOVERNANCE_ROLE");

    uint public epochLength = 7 days;
    uint public globalStartTimestamp;

    /// epoch index * epoch length = start time 

    mapping (uint => uint) public epochRate;

    event MintingStartTimeSet(uint globalStartTimestamp);
    event EpochSupplyRateSet(uint epoch, uint rate);
    
    function initialize(address _gac) public initializer {
        __GlobalAccessControlManaged_init(_gac);
        _setEpochRates();
    }

    // @dev duplicate of getMintable() with debug print added
    // @dev this function is out of scope for reviews and audits
    function getMintableDebug(uint lastMintTimestamp) external {
        require(globalStartTimestamp > 0, "SupplySchedule: minting not started");
        require(lastMintTimestamp > globalStartTimestamp, "SupplySchedule: attempting to mint before start block");
        require(block.timestamp > lastMintTimestamp, "SupplySchedule: already minted up to current block");

        uint mintable = 0;

        emit log_named_uint("mintable", mintable);
        emit log_named_uint("block.timestamp", block.timestamp);
        emit log_named_uint("lastMintTimestamp", lastMintTimestamp);
        emit log_named_uint("globalStartTimestamp", globalStartTimestamp);
        emit log_named_uint("epochLength", epochLength);
        
        uint startingEpoch = (lastMintTimestamp - globalStartTimestamp) / epochLength;
        emit log_named_uint("startingEpoch", startingEpoch);

        uint endingEpoch = (block.timestamp - globalStartTimestamp) / epochLength;
        emit log_named_uint("endingEpoch", endingEpoch);

        for (uint i = startingEpoch; i <= endingEpoch; i++) {
            uint rate = epochRate[i];

            uint epochStartTime = globalStartTimestamp + i * epochLength;
            uint epochEndTime = globalStartTimestamp + (i+1) * epochLength;

            emit log_named_uint("epoch iteration", i);
            emit log_named_uint("epochStartTime", epochStartTime);
            emit log_named_uint("epochEndTime", epochEndTime);

            uint time = MathUpgradeable.min(block.timestamp, epochEndTime) - MathUpgradeable.max(lastMintTimestamp, epochStartTime);

            emit log_named_uint("time to mint over", time);

            mintable += rate * time;

            emit log_named_uint("mintable from this iteration", rate * time);
            emit log_named_uint("total mintable after this iteration", mintable);
        }

        // return mintable;
    }

    
    function getEpochAtTimestamp(uint _timestamp) public view returns (uint256) {
        require(globalStartTimestamp > 0, "SupplySchedule: minting not started");
        return (_timestamp - globalStartTimestamp) / epochLength;
    }

    function getCurrentEpoch() public view returns (uint256) {
        return getEpochAtTimestamp(block.timestamp);
    }

    function getEmissionsForEpoch(uint _epoch) public view returns (uint256) {
        return epochRate[_epoch] * epochLength;
    }

    function getEmissionsForCurrentEpoch() public view returns (uint256) {
        uint epoch = getCurrentEpoch();
        return getEmissionsForEpoch(epoch);
    }

    function getMintable(uint lastMintTimestamp) external view returns (uint256) {
        require(globalStartTimestamp > 0, "SupplySchedule: minting not started");
        require(block.timestamp > lastMintTimestamp, "SupplySchedule: already minted up to current block");

        if (lastMintTimestamp < globalStartTimestamp) {
            lastMintTimestamp = globalStartTimestamp;
        }

        uint mintable = 0;
        
        uint startingEpoch = (lastMintTimestamp - globalStartTimestamp) / epochLength;

        uint endingEpoch = (block.timestamp - globalStartTimestamp) / epochLength;

        for (uint i = startingEpoch; i <= endingEpoch; i++) {
            uint rate = epochRate[i];

            uint epochStartTime = globalStartTimestamp + i * epochLength;
            uint epochEndTime = globalStartTimestamp + (i+1) * epochLength;

            uint time = MathUpgradeable.min(block.timestamp, epochEndTime) - MathUpgradeable.max(lastMintTimestamp, epochStartTime);

            mintable += rate * time;
        }

        return mintable;
    }

    function setMintingStart(uint _globalStartTimestamp) external onlyRole(CONTRACT_GOVERNANCE_ROLE) gacPausable {
        require(globalStartTimestamp == 0, "SupplySchedule: minting already started");
        require(_globalStartTimestamp >= 0, "SupplySchedule: minting must start at or after current time");

        globalStartTimestamp = _globalStartTimestamp;
        emit MintingStartTimeSet(_globalStartTimestamp);
    }

    function setEpochRate(uint _epoch, uint _rate) external onlyRole(CONTRACT_GOVERNANCE_ROLE) gacPausable {
        require(epochRate[_epoch] == 0, "SupplySchedule: rate already set for given epoch");
        // TODO: Require this epoch is in the future. What happens if no data is set? (It just fails to mint until set)
        epochRate[_epoch] = _rate;
        emit EpochSupplyRateSet(_epoch, _rate);
    }

    // @dev Set rates for the initial epochs
    function _setEpochRates() internal {
        epochRate[0] = 593962000000000000000000 / epochLength;
        epochRate[1] = 591445000000000000000000 / epochLength;
        epochRate[2] = 585021000000000000000000 / epochLength;
        epochRate[3] = 574138000000000000000000 / epochLength;
        epochRate[4] = 558275000000000000000000 / epochLength;
        epochRate[5] = 536986000000000000000000 / epochLength;
    }
}
