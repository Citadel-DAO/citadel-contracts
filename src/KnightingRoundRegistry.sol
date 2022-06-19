// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "./GACProxyAdmin.sol";
import "./lib/KnightingRoundData.sol";

/**
A simple registry contract that help to register different knighting round
*/
contract KnightingRoundRegistry is Initializable {
    // ===== Libraries  ====
    using KnightingRoundData for KnightingRoundData.RoundData;

    GACProxyAdmin public gacProxyAdmin;

    address public globalAccessControl;
    address public tokenOut;
    address public saleRecipient;
    address public guestlist;
    uint256 public roundStart;
    uint256 public roundDuration;

    address public knightingRoundImplementation;
    address public knightingRoundWithEthImplementation;

    address[] public knightingRounds;
    address public knightingRoundsWithEth;

    struct InitParam {
        address _tokenIn;
        uint256 _tokenInLimit;
        uint256 _tokenOutPerTokenIn;
    }

    /// initialize
    function initialize(
        address _knightingRoundImplementation,
        address _knightingRoundWithEthImplementation,
        bytes4 _selector,
        address _globalAccessControl,
        uint256 _roundStart,
        uint256 _roundDuration,
        address _tokenOut,
        address _saleRecipient,
        address _guestlist,
        InitParam calldata _wethParams,
        InitParam[] calldata _roundParams
    ) public initializer {
        globalAccessControl = _globalAccessControl;
        roundStart = _roundStart;
        roundDuration = _roundDuration;

        tokenOut = _tokenOut;
        saleRecipient = _saleRecipient;
        guestlist = _guestlist;

        gacProxyAdmin = new GACProxyAdmin();
        gacProxyAdmin.initialize(_globalAccessControl);

        knightingRoundImplementation = _knightingRoundImplementation;
        knightingRoundWithEthImplementation = _knightingRoundWithEthImplementation;

        /// for weth
        initializeRound(_wethParams, true, _selector);
        /// for other
        for (uint256 i = 0; i < _roundParams.length; i++) {
            initializeRound(_roundParams[i], true, _selector);
        }
        initializeRound(_wethParams, false, _selector);
    }

    function initializeRound(
        InitParam calldata _roundParams,
        bool _isNotEth,
        bytes4 _selector
    ) private {
        TransparentUpgradeableProxy currKnightingRound = new TransparentUpgradeableProxy(
                _isNotEth
                    ? address(knightingRoundImplementation)
                    : address(knightingRoundWithEthImplementation),
                address(gacProxyAdmin),
                abi.encodeWithSelector(
                    _selector,
                    globalAccessControl,
                    tokenOut,
                    _roundParams._tokenIn,
                    roundStart,
                    roundDuration,
                    _roundParams._tokenOutPerTokenIn,
                    saleRecipient,
                    guestlist,
                    _roundParams._tokenInLimit
                )
            );
        knightingRounds.push(address(currKnightingRound));
        if (!_isNotEth) {
            knightingRoundsWithEth = address(currKnightingRound);
        }
    }

    /// getRoundData
    function getRoundData(address _roundAddress)
        public
        view
        returns (KnightingRoundData.RoundData memory)
    {
        return
            KnightingRoundData.getRoundData(
                _roundAddress,
                knightingRoundsWithEth
            );
    }

    /// @notice using to get all rounds
    function getAllRounds() public view returns (address[] memory) {
        return knightingRounds;
    }

    /// @notice using to get all rounds
    function getAllRoundsData()
        public
        view
        returns (KnightingRoundData.RoundData[] memory)
    {
        return KnightingRoundData.getAllRoundsData(getAllRounds());
    }
}
