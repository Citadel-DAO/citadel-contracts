// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";

import "./lib/GlobalAccessControlManaged.sol";
import "./KnightingRound.sol";
import "./KnightingRoundWithEth.sol";

/**
A simple registry contract that help to register different knighting round
*/
contract KnightingRoundRegistry is GlobalAccessControlManaged {
    bytes32 public constant CONTRACT_GOVERNANCE_ROLE =
        keccak256("CONTRACT_GOVERNANCE_ROLE");

    uint256 public immutable PHASE_ONE_DURATION = 3 days;
    uint256 public immutable PHASE_TWO_DURATION = 2 days;

    address public governance;
    address public tokenOut;
    address public saleRecipient;
    address public guestList;

    uint256 public phaseOneStart;
    uint256 public phaseTwoState;

    /// initialize
    function initialize(
        address _governance,
        uint256 _phaseOneStart,
        address _tokenOut,
        address _saleRecipient,
        address _guestList
    ) public initializer {
        require(
            _phaseOneStart >= block.timestamp,
            "Phase one start can not be in past"
        );
    }
    /// initializePhaseOne
    /// initializePhaseTwo
    /// addToPhaseOne
    /// removeFromPhaseOne
    /// addToPhaseTwo
    /// getRoundData
    /// getPhaseOne
    /// getPhaseTwo
}
