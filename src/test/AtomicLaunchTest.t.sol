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

contract AtomicLaunchTest is BaseFixture {
    using FixedPointMathLib for uint256;

    event Sale(
        address indexed buyer,
        uint8 indexed daoId,
        uint256 amountIn,
        uint256 amountOut
    );

    uint256 constant MAX_UINT256 = type(uint256).max;

    address constant renBTC_owner = 0xe4b679400F0f267212D5D812B95f58C83243EE71;
    address constant ust_owner = 0x3ee18B2214AFF97000D974cf647E7C347E8fa585;
    address constant usdcMasterMinter =
        0xE982615d461DD5cD06575BbeA87624fda4e3de17;
    address constant usdcMasterMinter_owner =
        0x79E0946e1C186E745f1352d7C21AB04700C99F71;
    address constant usdc_owner = 0x5B6122C109B78C6755486966148C1D70a50A47D7;
    address constant badger_treasury =
        0xD0A7A8B98957b9CD3cFB9c0425AbE44551158e9e;

    // NOTE: wBTC and wETH are handled on fixture
    KnightingRound knightingRound_cvx = new KnightingRound();
    KnightingRound knightingRound_renBTC = new KnightingRound();
    KnightingRound knightingRound_ibBTC = new KnightingRound();
    KnightingRound knightingRound_frax = new KnightingRound();
    KnightingRound knightingRound_ust = new KnightingRound();
    KnightingRound knightingRound_usdc = new KnightingRound();
    KnightingRound knightingRound_badger = new KnightingRound();
    KnightingRound knightingRound_bveCVX = new KnightingRound();

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

        // knightingRoundBuy_ETH(
        //     knightingRoundWithEth,
        //     eth_user
        // );

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
            "Token in not received"
        );

        vm.stopPrank();
    }
}
