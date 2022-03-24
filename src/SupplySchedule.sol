// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {MathUpgradeable} from "openzeppelin-contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {SafeMathUpgradeable} from "openzeppelin-contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {AddressUpgradeable} from "openzeppelin-contracts-upgradeable/utils/AddressUpgradeable.sol";
import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/security/PausableUpgradeable.sol";
import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {IVault} from "./interfaces/IVault.sol";

import "./lib/GlobalAccessControlManaged.sol";

/**
Supply schedules are defined in terms of Epochs

*/
contract SupplySchedule is GlobalAccessControlManaged {
    bytes32 public constant CONTRACT_GOVERNANCE_ROLE = keccak256("CONTRACT_GOVERNANCE_ROLE");

    uint epochLength = 86400 * 7;
    uint globalStartTimestamp;
    uint lastMintTimestamp;

    /// epoch index * epoch length = start time 

    mapping (uint => uint) public epochRate;

    event MintingStartTimeSet(uint globalStartTimestamp);
    event EpochSupplyRateSet(uint epoch, uint rate);
    
    function initialize(address _gac) public initializer {
        __GlobalAccessControlManaged_init(_gac);
        _setEpochRates();
    }

    function getMintable() external view returns (uint256) {
        require(globalStartTimestamp > 0, "minting not started");
        uint mintable = 0;
        uint startingEpoch = lastMintTimestamp - globalStartTimestamp / epochLength;
        uint endingEpoch = block.timestamp - globalStartTimestamp / epochLength;

        for (uint i = startingEpoch; i <= endingEpoch; i++) {
            uint rate = epochRate[i];

            uint epochStartTime = globalStartTimestamp + i * epochLength;
            uint epochEndTime = globalStartTimestamp + (i+1) * epochLength;

            uint time = MathUpgradeable.min(block.timestamp, epochEndTime) - MathUpgradeable.max(lastMintTimestamp, epochStartTime);

            mintable += rate * time;
        }

        return mintable;
    }

    function setMintingStartTimestamp(uint _globalStartTimestamp) external onlyRole(CONTRACT_GOVERNANCE_ROLE) gacPausable {
        require(globalStartTimestamp == 0, "minting already started");
        require(_globalStartTimestamp >= 0, "minting must start at or after current time");

        globalStartTimestamp = _globalStartTimestamp;
        lastMintTimestamp = _globalStartTimestamp;
        emit MintingStartTimeSet(_globalStartTimestamp);
    }

    function setEpochRate(uint _epoch, uint _rate) external onlyRole(CONTRACT_GOVERNANCE_ROLE) gacPausable {
        require(epochRate[_epoch] == 0, "epoch rate already set");
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
