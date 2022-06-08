// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "openzeppelin-contracts/utils/structs/EnumerableSet.sol";

import {ChainlinkUtils} from "./oracles/ChainlinkUtils.sol";

import "./interfaces/curve/ICurvePoolFactory.sol";
import "./interfaces/curve/ICurvePool.sol";
import "./interfaces/citadel/IMedianOracleProvider.sol";
import "../interfaces/chainlink/IAggregatorV3Interface.sol";

contract AtomicLaunch is ChainlinkUtils {
    address constant CITADEL = 0x353a38c269A24aafb78Cd214c6E0668847Bb58FD;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant CURVE_POOL_FACTORY =
        0xF18056Bbd320E96A48e3Fbf8bC061322531aac99;
    uint256 constant CITADEL_PRICE = 21;

    IAggregatorV3Interface public wbtcBtcPriceFeed =
        IAggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);

    EnumerableSet.AddressSet internal _oracles;

    /* ========== EVENT ========== */
    event PoolCreated(address poolAddress);

    /// @param _governance Governance allowed to add oracles addresses and trigger launch (governance msig)
    constructor(address _governance) {
        governance = _governance;
    }

    /***************************************
                    MODIFIER
    ****************************************/

    modifier onlyGovernance() {
        require(msg.sender == governance, "not-governance!");
        _;
    }

    /***************************************
               ADMIN - GOVERNANCE
    ****************************************/

    function addOracle(address _oracleAddress) external onlyGovernance {
        require(_oracleAddress != address(0), "zero-address!");
        _oracles.add(_oracleAddress);
    }

    function launch(uint256 citadelToLiquidty, uint256 wbtcToLiquidity)
        external
        onlyGovernance
    {
        uint256 initialPoolPrice = _initialPoolPrice();

        address[2] memory coins;
        coins[0] = CITADEL;
        coins[1] = WBTC;

        address poolAddress = ICurvePoolFactory(CURVE_POOL_FACTORY).deploy_pool(
            "CTDL/wBTC",
            "CTDL",
            coins,
            400000,
            145000000000000,
            26000000,
            45000000,
            2000000000000,
            230000000000000,
            146000000000000,
            5000000000,
            600,
            initialPoolPrice
        );

        ICurvePool pool = ICurvePool(poolAddress);

        require(
            citadel.balanceOf(address(this)) >= citadelToLiquidty,
            "citadel funds not sent"
        );
        require(
            wbtc.balanceOf(address(this)) >= wbtcToLiquidity,
            "wbtc funds not sent"
        );

        citadel.approve(poolAddress, toLiquidity);
        wbtc.approve(poolAddress, wbtcToLiquidity);

        uint256[2] memory amounts;
        amounts[0] = citadelToLiquidty;
        amounts[1] = wbtcToLiquidity;

        pool.add_liquidity(amounts, 0);

        require(
            pool.balances(0) >= citadelToLiquidty,
            "pool balance incorrect"
        );
        require(pool.balances(1) >= wbtcToLiquidity, "pool balance incorrect");

        _setCurvePoolInOracles(poolAddress);

        // NOTE: mainly for clean event, so no needs for mega-detective work
        emit PoolCreated(poolAddress);
    }

    function _initialPoolPrice() internal returns (uint256 _poolPrice) {
        (uint256 wbtcOraclePricing, , bool valid) = safeLatestAnswer(
            wbtcBtcPriceFeed
        );

        require(valid, "not-valid!");

        uint256 wbtcPrice = wbtcOraclePricing / 10**wbtcBtcPriceFeed.decimals();

        _poolPrice = (wbtcPrice / CITADEL_PRICE) * 1e18;
    }

    function _setCurvePoolInOracles(address _ctdlWbtcCurvePool) internal {
        for (uint256 i = 0; i < _oracles.length(); i++) {
            IMedianOracleProvider(_oracles.at(i)).setCurvePool(
                _ctdlWbtcCurvePool
            );
        }
    }
}
