// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "openzeppelin-contracts/utils/structs/EnumerableSet.sol";

import {ChainlinkUtils} from "./oracles/ChainlinkUtils.sol";
import {CtdlWbtcCurveV2Provider} from "./oracles/CtdlWbtcCurveV2Provider.sol";
import {CtdlAssetChainlinkProvider} from "./oracles/CtdlAssetChainlinkProvider.sol";
import {CtdlBtcChainlinkProvider} from "./oracles/CtdlBtcChainlinkProvider.sol";
import {CtdlEthChainlinkProvider} from "./oracles/CtdlEthChainlinkProvider.sol";
import {CtdlWibbtcLpVaultProvider} from "./oracles/CtdlWibbtcLpVaultProvider.sol";

import "./interfaces/erc20/IERC20.sol";
import "./interfaces/curve/ICurvePoolFactory.sol";
import "./interfaces/curve/ICurvePool.sol";
import "./interfaces/chainlink/IAggregatorV3Interface.sol";

contract AtomicLaunch is ChainlinkUtils {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public citadel;
    address public wbtc;

    address public constant WBTC_BTC_PRICE_FEED =
        0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23;
    address public constant BTC_ETH_PRICE_FEED =
        0xdeb288F737066589598e9214E782fa5A8eD689e8;

    address public constant ETH_USD_PRICE_FEED =
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    address public constant WIBBTC_LP_VAULT =
        0xaE96fF08771a109dc6650a1BdCa62F2d558E40af;

    address public constant FRAX_ETH_PRICE_FEED =
        0x14d04Fff8D21bd62987a5cE9ce543d2F1edF5D3E;
    address public constant FRAX_USD_PRICE_FEED =
        0xB9E1E3A9feFf48998E45Fa90847ed4D467E8BcfD;

    address public constant USDC_ETH_PRICE_FEED =
        0x986b5E1e1755e3C2440e960477f25201B0a8bbD4;
    address public constant USDC_USD_PRICE_FEED =
        0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;

    address public constant CVX_ETH_PRICE_FEED =
        0xC9CbF687f43176B302F03f5e58470b77D07c61c6;
    address public constant CVX_USD_PRICE_FEED =
        0xd962fC30A72A84cE50161031391756Bf2876Af5D;

    address public constant BADGER_ETH_PRICE_FEED =
        0x58921Ac140522867bf50b9E009599Da0CA4A2379;
    address public constant BADGER_USD_PRICE_FEED =
        0x66a47b7206130e6FF64854EF0E1EDfa237E65339;

    address public constant CURVE_POOL_FACTORY =
        0xF18056Bbd320E96A48e3Fbf8bC061322531aac99;
    uint256 public constant CITADEL_PRICE = 21;

    IAggregatorV3Interface public constant wbtcUsdPriceFeed =
        IAggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);

    /* ========== STATE VARIABLES ========== */
    address public governance;

    EnumerableSet.AddressSet internal _oracles;

    /* ========== EVENT ========== */
    event PoolCreated(address poolAddress);

    /// @param _governance Governance allowed to add oracles addresses and trigger launch (governance msig)
    constructor(
        address _governance,
        address _citadel,
        address _wbtc
    ) {
        governance = _governance;
        citadel = _citadel;
        wbtc = _wbtc;
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

    function launch(uint256 citadelToLiquidity, uint256 wbtcToLiquidity)
        external
        onlyGovernance
    {
        uint256 initialPoolPrice = _initialPoolPrice();

        address[2] memory coins;
        coins[0] = citadel;
        coins[1] = wbtc;

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
            IERC20(citadel).balanceOf(address(this)) >= citadelToLiquidity,
            "<citadelToLiquidity!"
        );
        require(
            IERC20(wbtc).balanceOf(address(this)) >= wbtcToLiquidity,
            "<wbtcToLiquidity!"
        );

        IERC20(citadel).approve(poolAddress, citadelToLiquidity);
        IERC20(wbtc).approve(poolAddress, wbtcToLiquidity);

        uint256[2] memory amounts;
        amounts[0] = citadelToLiquidity;
        amounts[1] = wbtcToLiquidity;

        pool.add_liquidity(amounts, 0);

        require(
            pool.balances(0) >= citadelToLiquidity,
            "<pool-curve-citadelToLiquidity!"
        );
        require(
            pool.balances(1) >= wbtcToLiquidity,
            "<pool-curve-wbtcToLiquidity!"
        );

        _deployOracles(poolAddress);

        // NOTE: mainly for clean event, so no needs for mega-detective work
        emit PoolCreated(poolAddress);
    }

    function _initialPoolPrice() internal returns (uint256 _poolPrice) {
        (uint256 wbtcOraclePricing, , bool valid) = safeLatestAnswer(
            wbtcUsdPriceFeed
        );

        require(valid, "not-valid!");

        uint256 wbtcPrice = wbtcOraclePricing / 10**wbtcUsdPriceFeed.decimals();

        _poolPrice = (wbtcPrice / CITADEL_PRICE) * 1e18;
    }

    function _deployOracles(address _ctdlWbtcCurvePool) internal {
        CtdlWbtcCurveV2Provider ctdlWbtcProviderLoc = new CtdlWbtcCurveV2Provider(
                _ctdlWbtcCurvePool
            );
        _oracles.add(address(ctdlWbtcProviderLoc));

        CtdlBtcChainlinkProvider ctdlBtcProvider = new CtdlBtcChainlinkProvider(
            _ctdlWbtcCurvePool,
            WBTC_BTC_PRICE_FEED
        );
        _oracles.add(address(ctdlBtcProvider));

        CtdlWibbtcLpVaultProvider ctdlWibbtcProvider = new CtdlWibbtcLpVaultProvider(
                _ctdlWbtcCurvePool,
                WBTC_BTC_PRICE_FEED,
                WIBBTC_LP_VAULT
            );
        _oracles.add(address(ctdlWibbtcProvider));

        CtdlEthChainlinkProvider ctdlEthProvider1 = new CtdlEthChainlinkProvider(
                _ctdlWbtcCurvePool,
                WBTC_BTC_PRICE_FEED,
                BTC_ETH_PRICE_FEED
            );
        _oracles.add(address(ctdlEthProvider1));

        CtdlAssetChainlinkProvider ctdlEthProvider2 = new CtdlAssetChainlinkProvider(
                _ctdlWbtcCurvePool,
                WBTC_BTC_PRICE_FEED,
                address(wbtcUsdPriceFeed),
                ETH_USD_PRICE_FEED
            );
        _oracles.add(address(ctdlEthProvider2));

        address[4] memory assetEthFeeds = [
            FRAX_ETH_PRICE_FEED,
            USDC_ETH_PRICE_FEED,
            CVX_ETH_PRICE_FEED,
            BADGER_ETH_PRICE_FEED
        ];

        address[4] memory assetUsdFeeds = [
            FRAX_USD_PRICE_FEED,
            USDC_USD_PRICE_FEED,
            CVX_USD_PRICE_FEED,
            BADGER_USD_PRICE_FEED
        ];

        for (uint256 i; i < 4; ++i) {
            CtdlAssetChainlinkProvider ctdlAssetProvider1 = new CtdlAssetChainlinkProvider(
                    _ctdlWbtcCurvePool,
                    WBTC_BTC_PRICE_FEED,
                    BTC_ETH_PRICE_FEED,
                    assetUsdFeeds[i]
                );
            _oracles.add(address(ctdlAssetProvider1));

            CtdlAssetChainlinkProvider ctdlAssetProvider2 = new CtdlAssetChainlinkProvider(
                    _ctdlWbtcCurvePool,
                    WBTC_BTC_PRICE_FEED,
                    address(wbtcUsdPriceFeed),
                    assetEthFeeds[i]
                );
            _oracles.add(address(ctdlAssetProvider2));
        }
    }

    /***************************************
               PUBLIC FUNCTION
    ****************************************/

    function getAllOracles() public view returns (address[] memory) {
        return _oracles.values();
    }
}
