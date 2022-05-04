// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";

import "./KnightingRound.sol";
import "./KnightingRoundWithEth.sol";

/**
A simple registry contract that help to register different knighting round
*/
contract KnightingRoundRegistry is Initializable {
    // ===== Libraries  ====
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant CONTRACT_GOVERNANCE_ROLE =
        keccak256("CONTRACT_GOVERNANCE_ROLE");

    address public governance;
    address public tokenOut;
    address public saleRecipient;
    address public guestlist;
    uint256 public roundStart;
    uint256 public roundDuration;

    address public knightingRoundImplementation;
    address public knightingRoundWithEthImplementation;

    EnumerableSet.AddressSet private knightingRounds;

    struct initParam {
        address _tokenIn;
        uint256 _tokenInLimit;
        uint256 _tokenOutPerTokenIn;
    }

    struct RoundData {
        address roundAddress;
        address tokenOut;
        address tokenIn;
        uint256 saleStart;
        uint256 saleDuration;
        address saleRecipient;
        bool finalized;
        uint256 tokenOutPerTokenIn;
        uint256 totalTokenIn;
        uint256 totalTokenOutBought;
        uint256 totalTokenOutClaimed;
        uint256 tokenInLimit;
        uint256 tokenInNormalizationValue;
        address guestlist;
        bool isEth;
    }

    /// initialize
    function initialize(
        address _governance,
        uint256 _roundStart,
        uint256 _roundDuration,
        address _tokenOut,
        address _saleRecipient,
        address _guestlist,
        initParam calldata _wethParams,
        initParam[] calldata _roundParams
    ) public initializer {
        governance = _governance;
        roundStart = _roundStart;
        roundDuration = _roundDuration;

        tokenOut = _tokenOut;
        saleRecipient = _saleRecipient;
        guestlist = _guestlist;
        knightingRoundImplementation = address(new KnightingRound());
        knightingRoundWithEthImplementation = address(
            new KnightingRoundWithEth()
        );

        /// for weth
        initializeEthRounds(_wethParams);
        /// for other
        for (uint256 i = 0; i < _roundParams.length; i++) {
            address currKnightingRound = Clones.clone(
                knightingRoundImplementation
            );
            initializeRound(currKnightingRound, _roundParams[i]);
        }
    }

    function initializeRound(
        address _roundAddress,
        initParam calldata _roundParams
    ) private {
        KnightingRound(_roundAddress).initialize(
            governance,
            tokenOut,
            _roundParams._tokenIn,
            roundStart,
            roundDuration,
            _roundParams._tokenOutPerTokenIn,
            saleRecipient,
            guestlist,
            _roundParams._tokenInLimit
        );
        knightingRounds.add(_roundAddress);
    }

    function initializeEthRounds(initParam calldata _roundParams) private {
        initializeRound(knightingRoundImplementation, _roundParams);
        KnightingRoundWithEth(knightingRoundWithEthImplementation).initialize(
            governance,
            tokenOut,
            _roundParams._tokenIn,
            roundStart,
            roundDuration,
            _roundParams._tokenOutPerTokenIn,
            saleRecipient,
            guestlist,
            _roundParams._tokenInLimit
        );
        knightingRounds.add(knightingRoundImplementation);
    }

    /// getRoundData
    function getRoundData(address _roundAddress)
        public
        view
        returns (RoundData memory roundData)
    {
        KnightingRound targetRound = KnightingRound(_roundAddress);
        roundData.roundAddress = _roundAddress;
        roundData.tokenOut = address(targetRound.tokenOut());
        roundData.tokenIn = address(targetRound.tokenIn());
        roundData.saleStart = targetRound.saleStart();
        roundData.saleDuration = targetRound.saleDuration();
        roundData.saleRecipient = targetRound.saleRecipient();
        roundData.finalized = targetRound.finalized();
        roundData.tokenOutPerTokenIn = targetRound.tokenOutPerTokenIn();
        roundData.totalTokenIn = targetRound.totalTokenIn();
        roundData.totalTokenOutBought = targetRound.totalTokenOutBought();
        roundData.totalTokenOutClaimed = targetRound.totalTokenOutClaimed();
        roundData.tokenInLimit = targetRound.tokenInLimit();
        roundData.tokenInNormalizationValue = targetRound
            .tokenInNormalizationValue();
        roundData.guestlist = address(targetRound.guestlist());
        if (_roundAddress == knightingRoundWithEthImplementation) {
            roundData.isEth = true;
        } else {
            roundData.isEth = false;
        }
    }

    /// @notice using to get all rounds
    function getAllRounds() public view returns (address[] memory) {
        address[] memory knightingRoundsList = new address[](
            knightingRounds.length() + 1
        );
        for (uint256 i = 0; i < knightingRounds.length(); i++) {
            knightingRoundsList[i] = knightingRounds.at(i);
        }
        knightingRoundsList[
            knightingRounds.length()
        ] = knightingRoundWithEthImplementation;
        return knightingRoundsList;
    }

    /// @notice using to get all rounds
    function getAllRoundsData() public view returns (RoundData[] memory) {
        RoundData[] memory roundsData = new RoundData[](
            knightingRounds.length() + 1
        );
        for (uint256 i = 0; i < knightingRounds.length(); i++) {
            roundsData[i] = getRoundData(knightingRounds.at(i));
        }
        roundsData[knightingRounds.length()] = getRoundData(
            knightingRoundWithEthImplementation
        );
        return roundsData;
    }
}
