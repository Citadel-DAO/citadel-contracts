// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";
import "ds-test/test.sol";

import "./lib/GlobalAccessControlManaged.sol";
import "./KnightingRound.sol";
import "./KnightingRoundWithEth.sol";

/**
A simple registry contract that help to register different knighting round
*/
contract KnightingRoundRegistry is GlobalAccessControlManaged {
    // ===== Libraries  ====
    using EnumerableSet for EnumerableSet.AddressSet;

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

    EnumerableSet.AddressSet private knightingRounds;

    struct initParam {
        address _tokenIn;
        uint256 _tokenInLimit;
        uint256 _tokenOutPrice;
    }

    /// initialize
    function initialize(
        address _governance,
        uint256 _phaseOneStart,
        address _tokenOut,
        address _saleRecipient,
        address _guestlist,
        initParam calldata _wethParams,
        initParam[] calldata _roundParams
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
        guestList = _guestlist;
        knightingRoundImplementation = address(new KnightingRound());
        knightingRoundWithEthImplementation = address(
            new KnightingRoundWithEth()
        );

        /// for weth
        initializeRound(_wethParams);
        // both weth and withEth
        /// for other
        for (uint256 i = 0; i < _roundParams.length; i++) {
            initializeRound(_roundParams[i]);
        }
    }

    function initializeRound(initParam calldata _roundParams) private {
        address currKnightingRound = Clones.clone(knightingRoundImplementation);
        KnightingRound(currKnightingRound).initialize(
            governance,
            tokenOut,
            _roundParams._tokenIn,
            phaseOneStart,
            PHASE_ONE_DURATION,
            _roundParams._tokenOutPrice,
            saleRecipient,
            guestList,
            _roundParams._tokenInLimit
        );
        knightingRounds.add(currKnightingRound);
    }

    function initializeEthRounds(initParam calldata _roundParams) private {
        KnightingRound(knightingRoundImplementation).initialize(
            governance,
            tokenOut,
            _roundParams._tokenIn,
            phaseOneStart,
            PHASE_ONE_DURATION,
            _roundParams._tokenOutPrice,
            saleRecipient,
            guestList,
            _roundParams._tokenInLimit
        );
        KnightingRoundWithEth(knightingRoundWithEthImplementation).initialize(
            governance,
            tokenOut,
            _roundParams._tokenIn,
            phaseOneStart,
            PHASE_ONE_DURATION,
            _roundParams._tokenOutPrice,
            saleRecipient,
            guestList,
            _roundParams._tokenInLimit
        );
        knightingRounds.add(knightingRoundImplementation);
    }

    /// getRoundData
    /// getPhaseOne
}
