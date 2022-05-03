// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";
import "ds-test/test.sol";

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

    address public governance;
    address public tokenOut;
    address public saleRecipient;
    address public guestList;

    uint256 public phaseOneStart;

    address public knightingRoundImplementation;
    address public knightingRoundWithEthImplementation;

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
        require(
            _saleRecipient != address(0),
            "KnightingRound: sale recipient should not be zero"
        );
        require(
            _tokenOut != address(0),
            "Tokenout: token out should not be zero"
        );
        require(
            _governance != address(0),
            "Tokenout: token out should not be zero"
        );
        __GlobalAccessControlManaged_init(_governance);
        governance = _governance;
        phaseOneStart = _phaseOneStart;
        tokenOut = _tokenOut;
        saleRecipient = _saleRecipient;
        guestList = _guestList;
        knightingRoundImplementation = address(new KnightingRound());
        knightingRoundWithEthImplementation = address(
            new KnightingRoundWithEth()
        );
    }
    /// initializePhaseOne
    /// addToPhaseOne
    /// removeFromPhaseOne
    /// addToPhaseTwo
    /// getRoundData
    /// getPhaseOne
    /// getPhaseTwo
}
