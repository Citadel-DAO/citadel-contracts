pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {KnightingRound} from "../KnightingRound.sol";
import {KnightingRoundWithEth} from "../KnightingRoundWithEth.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import "../interfaces/erc20/IERC20.sol";

// General interfaces for special non-ERC20 tokens' mint function
interface ISpecialMinter {
    function mint(address account, uint256 amount) external;
}

interface IUSDCMasterMinter {
    function incrementMinterAllowance(uint256 _allowanceIncrement) external;
}

// Curve Pool Factory
interface ICurvePoolFactory {
    function deploy_pool(
        string memory _name,
        string memory _symbol,
        address[2] memory _coins,
        uint256 A,
        uint256 gamma,
        uint256 mid_fee,
        uint256 out_fee,
        uint256 allowed_extra_profit,
        uint256 fee_gamma,
        uint256 adjustment_step,
        uint256 admin_fee,
        uint256 ma_half_time,
        uint256 initial_price
    ) external returns (address);
}

interface ICurvePool {
    function token() external view returns (address);

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external;

    function balances(uint256 arg0) external view returns (uint256);
}

contract AtomicLaunchTest is BaseFixture {
    using FixedPointMathLib for uint256;

    event Sale(
        address indexed buyer,
        uint8 indexed daoId,
        uint256 amountIn,
        uint256 amountOut
    );

    uint256 constant MAX_UINT256 = type(uint256).max;

    // Asset minting addresses (Just for testing)
    address constant renBTC_owner = 0xe4b679400F0f267212D5D812B95f58C83243EE71;
    address constant ust_owner = 0x3ee18B2214AFF97000D974cf647E7C347E8fa585;
    address constant usdcMasterMinter =
        0xE982615d461DD5cD06575BbeA87624fda4e3de17;
    address constant usdcMasterMinter_owner =
        0x79E0946e1C186E745f1352d7C21AB04700C99F71;
    address constant usdc_owner = 0x5B6122C109B78C6755486966148C1D70a50A47D7;
    address constant badger_treasury =
        0xD0A7A8B98957b9CD3cFB9c0425AbE44551158e9e;

    // Involved addresses
    address constant curvePoolFactory =
        0xF18056Bbd320E96A48e3Fbf8bC061322531aac99;

    // NOTE: wBTC and wETH are handled on fixture
    KnightingRound knightingRound_cvx = new KnightingRound();
    KnightingRound knightingRound_renBTC = new KnightingRound();
    KnightingRound knightingRound_ibBTC = new KnightingRound();
    KnightingRound knightingRound_frax = new KnightingRound();
    KnightingRound knightingRound_ust = new KnightingRound();
    KnightingRound knightingRound_usdc = new KnightingRound();
    KnightingRound knightingRound_badger = new KnightingRound();
    KnightingRound knightingRound_bveCVX = new KnightingRound();

    KnightingRound[] roundsArray;

    address btc_user = address(1);
    address stable_user = address(2);
    address influence_user = address(3);
    address eth_user = address(4);

    function setUp() public override {
        BaseFixture.setUp();

        // There will be no tokenIn limit (Round can only finish based on time)
        vm.startPrank(techOps);
        knightingRound.setTokenInLimit(MAX_UINT256); // wBTC
        knightingRoundWithEth.setTokenInLimit(MAX_UINT256);
        vm.stopPrank();

        // Setup rounds with somehow realistic prices
        vm.startPrank(governance);
        knightingRound.setTokenOutPerTokenIn(1500e18); //1500 xCTDL per wBTC
        knightingRoundWithEth.setTokenOutPerTokenIn(115e18); // 115 xCTDL per ETH

        roundsArray.push(knightingRound);

        knightingRound_renBTC.initialize(
            address(gac),
            address(xCitadel),
            address(renBTC),
            knightingRoundParams.start,
            knightingRoundParams.duration,
            1500e18, // 1500 xCTDL per renBTC
            address(governance),
            address(guestList),
            MAX_UINT256
        );
        roundsArray.push(knightingRound_renBTC);

        knightingRound_ibBTC.initialize(
            address(gac),
            address(xCitadel),
            address(ibBTC),
            knightingRoundParams.start,
            knightingRoundParams.duration,
            1500e18, // 1500 xCTDL per ibBTC
            address(governance),
            address(guestList),
            MAX_UINT256
        );
        roundsArray.push(knightingRound_ibBTC);

        knightingRound_frax.initialize(
            address(gac),
            address(xCitadel),
            address(frax),
            knightingRoundParams.start,
            knightingRoundParams.duration,
            47619047610000000, // 0.0476 xCTDL per frax
            address(governance),
            address(guestList),
            MAX_UINT256
        );
        roundsArray.push(knightingRound_frax);

        knightingRound_ust.initialize(
            address(gac),
            address(xCitadel),
            address(ust),
            knightingRoundParams.start,
            knightingRoundParams.duration,
            47619047610000000, // 0.0476 xCTDL per ust
            address(governance),
            address(guestList),
            MAX_UINT256
        );
        roundsArray.push(knightingRound_ust);

        knightingRound_usdc.initialize(
            address(gac),
            address(xCitadel),
            address(usdc),
            knightingRoundParams.start,
            knightingRoundParams.duration,
            47619047610000000, // 0.0476 xCTDL per usdc
            address(governance),
            address(guestList),
            MAX_UINT256
        );
        roundsArray.push(knightingRound_usdc);

        knightingRound_cvx.initialize(
            address(gac),
            address(xCitadel),
            address(cvx),
            knightingRoundParams.start,
            knightingRoundParams.duration,
            1e18, // 1 xCTDL per CVX
            address(governance),
            address(guestList),
            MAX_UINT256
        );
        roundsArray.push(knightingRound_cvx);

        knightingRound_bveCVX.initialize(
            address(gac),
            address(xCitadel),
            address(bveCVX),
            knightingRoundParams.start,
            knightingRoundParams.duration,
            1e18, // 1 xCTDL per bveCVX
            address(governance),
            address(guestList),
            MAX_UINT256
        );
        roundsArray.push(knightingRound_bveCVX);

        knightingRound_badger.initialize(
            address(gac),
            address(xCitadel),
            address(badger),
            knightingRoundParams.start,
            knightingRoundParams.duration,
            333333333333333333, // 0.333 xCTDL per badger
            address(governance),
            address(guestList),
            MAX_UINT256
        );
        roundsArray.push(knightingRound_badger);

        vm.stopPrank();

        // Mint assets for users

        // Mint BTC based assets
        erc20utils.forceMintTo(btc_user, wbtc_address, 1000e8);
        erc20utils.forceMintTo(btc_user, ibBTC_address, 1000e18);
        vm.prank(renBTC_owner); // RenBTC Owner
        ISpecialMinter(renBTC_address).mint(btc_user, 1000e8);

        // Mint Stablecoin assets
        erc20utils.forceMintTo(stable_user, frax_address, 100000e18);
        vm.prank(ust_owner); // UST Owner
        ISpecialMinter(ust_address).mint(stable_user, 100000e6);
        vm.prank(usdcMasterMinter_owner);
        IUSDCMasterMinter(usdcMasterMinter).incrementMinterAllowance(100000e6);
        vm.prank(usdc_owner); // USDC Owner
        ISpecialMinter(usdc_address).mint(stable_user, 100000e6);

        // Mint influence assets
        erc20utils.forceMintTo(influence_user, cvx_address, 10000e18);
        vm.startPrank(badger_treasury);
        bveCVX.transfer(influence_user, bveCVX.balanceOf(badger_treasury));
        badger.transfer(influence_user, badger.balanceOf(badger_treasury));
        require(bveCVX.balanceOf(influence_user) > 0, "No bveCVX tranferred");
        require(badger.balanceOf(influence_user) > 0, "No BADGER tranferred");
        vm.stopPrank();

        // Deal ETH
        vm.deal(eth_user, 100 ether);
    }

    function testAtomicLaunch() public {
        _simulateeKnightingRound();

        vm.startPrank(governance);

        // Get all the Citadel bought from all KRs
        uint256 totalCitadelBought;
        uint256[] memory citdatelBoughtPerRound = new uint256[](
            roundsArray.length
        );
        for (uint256 i; i < roundsArray.length; i++) {
            totalCitadelBought += roundsArray[i].totalTokenOutBought();
            citdatelBoughtPerRound[i] = roundsArray[i].totalTokenOutBought();
        }
        uint256 citadelBoughtEthRound = knightingRoundWithEth
            .totalTokenOutBought();
        totalCitadelBought += citadelBoughtEthRound;

        // Mint the required TotalSupply of CTDL
        uint256 initialSupply = (totalCitadelBought * 1666666666666666667) /
            1e18; // Amount bought = 60% of initial supply, therefore total citadel ~= 1.67 amount bought.

        citadel.mint(governance, initialSupply);
        assertEq(citadel.balanceOf(governance), initialSupply);

        // Distribute bought amounts of xCTDL to each round
        citadel.approve(address(xCitadel), totalCitadelBought);

        for (uint256 i; i < roundsArray.length; i++) {
            xCitadel.depositFor(
                address(roundsArray[i]),
                citdatelBoughtPerRound[i]
            );
            assertEq(
                xCitadel.balanceOf(address(roundsArray[i])),
                citdatelBoughtPerRound[i]
            );
        }
        xCitadel.depositFor(
            address(knightingRoundWithEth),
            citadelBoughtEthRound
        );
        assertEq(
            xCitadel.balanceOf(address(knightingRoundWithEth)),
            citadelBoughtEthRound
        );
        assertEq(xCitadel.balanceOf(governance), 0);

        // Seed xCTDL
        uint256 remainingSupply = initialSupply - totalCitadelBought - 1e18; // one coin for seeding xCitadel

        citadel.approve(address(xCitadel), 1e18);
        xCitadel.deposit(1e18);
        assertEq(xCitadel.balanceOf(governance), 1e18);

        // Transfer 25% of total CTDL and acquired sale assets to Treasury
        uint256 toTreasury = (remainingSupply * 6e17) / 1e18; // 25% of total, or 60% of remaining 40%

        citadel.transfer(treasuryVault, toTreasury);
        assertEq(citadel.balanceOf(treasuryVault), toTreasury);

        for (uint256 i; i < roundsArray.length; i++) {
            IERC20 tokenIn = IERC20(address(roundsArray[i].tokenIn()));
            uint256 govTokenInBalance = tokenIn.balanceOf(governance);
            tokenIn.transfer(treasuryVault, govTokenInBalance);
            assertEq(tokenIn.balanceOf(governance), 0);
            assertEq(tokenIn.balanceOf(treasuryVault), govTokenInBalance);
        }
        uint256 govWethBalance = weth.balanceOf(governance);
        weth.transfer(treasuryVault, govWethBalance);
        assertEq(weth.balanceOf(governance), 0);
        assertEq(weth.balanceOf(treasuryVault), govWethBalance);

        // Use 15% of total CTDL to deploy and seed liquidity pool on Curve
        uint256 toLiquidity = (remainingSupply * 4e17) / 1e18; // 15% of total, or 40% of remaining 40%
        address[2] memory coins;
        coins[0] = address(citadel);
        coins[1] = address(wbtc);

        // NOTE: Parameters acquired from test deployment:
        // https://etherscan.io/tx/0x20a9182e7644e216d7a26785223fb2947a3ba70998eac4da98a63ec4652b1821
        address poolAddress = ICurvePoolFactory(curvePoolFactory).deploy_pool(
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
            1428571428570000000000 // ~$30k/$21 = 1428.57142857 (Current external rate for WBTC/CTDL)
        );

        ICurvePool pool = ICurvePool(poolAddress);

        // Calculate wBTC amount as: $21/~$30k = 0.0007
        uint256 wbtcToLiquidity = ((toLiquidity * 7e14) / 1e18) / 1e10; // Divide by 1e10 to normalize to wBTC decimals
        emit log_named_uint("CTDL Liquidity", toLiquidity);
        emit log_named_uint("wBTC Liquidity", wbtcToLiquidity);
        erc20utils.forceMintTo(governance, wbtc_address, wbtcToLiquidity);

        citadel.approve(poolAddress, toLiquidity);
        wbtc.approve(poolAddress, wbtcToLiquidity);

        uint256[2] memory amounts;
        amounts[0] = toLiquidity;
        amounts[1] = wbtcToLiquidity;
        pool.add_liquidity(amounts, 0);

        assertEq(pool.balances(0), toLiquidity);
        assertEq(pool.balances(1), wbtcToLiquidity);
    }

    function _simulateeKnightingRound() public {
        // Move to knighting round start
        vm.warp(knightingRound.saleStart());

        knightingRoundBuy(knightingRound, wbtc, btc_user);
        knightingRoundBuy(knightingRound_ibBTC, ibBTC, btc_user);
        knightingRoundBuy(knightingRound_renBTC, renBTC, btc_user);
        knightingRoundBuy(knightingRound_frax, frax, stable_user);
        knightingRoundBuy(knightingRound_ust, ust, stable_user);
        knightingRoundBuy(knightingRound_usdc, usdc, stable_user);
        knightingRoundBuy(knightingRound_cvx, cvx, influence_user);
        knightingRoundBuy(knightingRound_bveCVX, bveCVX, influence_user);
        knightingRoundBuy(knightingRound_badger, badger, influence_user);
        knightingRoundBuy_ETH(knightingRoundWithEth, eth_user);

        vm.stopPrank();

        // Knighting round concludes...
        uint256 timeTillEnd = knightingRoundParams.start +
            knightingRoundParams.duration -
            block.timestamp;

        vm.warp(timeTillEnd);
    }

    function knightingRoundBuy(
        KnightingRound round,
        IERC20 tokenIn,
        address user
    ) internal {
        bytes32[] memory emptyProof = new bytes32[](1);
        vm.startPrank(user);

        uint256 amountIn = tokenIn.balanceOf(user);

        tokenIn.approve(address(round), amountIn);

        uint256 tokenOutAmountExpected = (amountIn *
            round.tokenOutPerTokenIn()) / round.tokenInNormalizationValue();

        vm.expectEmit(true, true, false, true);
        emit Sale(user, 0, amountIn, tokenOutAmountExpected);
        uint256 tokenOutAmount = round.buy(amountIn, 0, emptyProof);

        assertEq(round.totalTokenIn(), amountIn); // totalTokenIn should be equal to deposit
        assertEq(tokenOutAmount, tokenOutAmountExpected); // transferred amount should be equal to expected
        assertEq(round.totalTokenOutBought(), tokenOutAmount);
        assertEq(round.daoVotedFor(user), 0); // daoVotedFor should be set
        assertEq(round.daoCommitments(0), tokenOutAmount); // daoCommitments should be tokenOutAmount

        require(tokenIn.balanceOf(user) == 0, "Token in not deposited");
        require(
            tokenIn.balanceOf(round.saleRecipient()) == amountIn,
            "Token in not received"
        );

        vm.stopPrank();
    }

    function knightingRoundBuy_ETH(KnightingRoundWithEth round, address user)
        internal
    {
        bytes32[] memory emptyProof = new bytes32[](1);
        vm.startPrank(user);

        uint256 amountIn = user.balance;

        weth.approve(address(round), amountIn);

        uint256 tokenOutAmountExpected = (amountIn *
            round.tokenOutPerTokenIn()) / round.tokenInNormalizationValue();

        vm.expectEmit(true, true, false, true);
        emit Sale(user, 0, amountIn, tokenOutAmountExpected);
        uint256 tokenOutAmount = round.buyEth{value: amountIn}(0, emptyProof);

        assertEq(round.totalTokenIn(), amountIn); // totalTokenIn should be equal to deposit
        assertEq(tokenOutAmount, tokenOutAmountExpected); // transferred amount should be equal to expected
        assertEq(round.totalTokenOutBought(), tokenOutAmount);
        assertEq(round.daoVotedFor(user), 0); // daoVotedFor should be set
        assertEq(round.daoCommitments(0), tokenOutAmount); // daoCommitments should be tokenOutAmount

        require(user.balance == 0, "ETH in not deposited");
        require(
            weth.balanceOf(round.saleRecipient()) == amountIn,
            "wETH in not received"
        );

        vm.stopPrank();
    }
}
