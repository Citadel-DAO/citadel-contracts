// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdCheats} from "forge-std/stdlib.sol";
import {Utils} from "./utils/Utils.sol";
import {ERC20Utils} from "./utils/ERC20Utils.sol";
import {SnapshotComparator} from "./utils/SnapshotUtils.sol";

import {GlobalAccessControl} from "../GlobalAccessControl.sol";

import {CitadelToken} from "../CitadelToken.sol";
import {StakedCitadel} from "../StakedCitadel.sol";
import {BrickedStrategy} from "../BrickedStrategy.sol";
import {StakedCitadelVester} from "../StakedCitadelVester.sol";

import {SupplySchedule} from "../SupplySchedule.sol";
import {CitadelMinter} from "../CitadelMinter.sol";

import {KnightingRound} from "../KnightingRound.sol";
import {KnightingRoundWithEth} from "../KnightingRoundWithEth.sol";
import {KnightingRoundGuestlist} from "../KnightingRoundGuestlist.sol";
import {Funding} from "../Funding.sol";

import "../interfaces/erc20/IERC20.sol";
import "../interfaces/badger/IEmptyStrategy.sol";
import "../interfaces/citadel/IStakedCitadelLocker.sol";
import {IMedianOracle} from "../interfaces/citadel/IMedianOracle.sol";

string constant lockerArtifact = "artifacts-external/StakedCitadelLocker.json";
string constant medianOracleArtifact = "artifacts-external/MedianOracle.json";

contract BaseFixture is DSTest, Utils, stdCheats {
    Vm constant vm = Vm(HEVM_ADDRESS);
    ERC20Utils immutable erc20utils = new ERC20Utils();
    SnapshotComparator comparator;

    bytes32 public constant CONTRACT_GOVERNANCE_ROLE =
        keccak256("CONTRACT_GOVERNANCE_ROLE");
    bytes32 public constant TREASURY_GOVERNANCE_ROLE =
        keccak256("TREASURY_GOVERNANCE_ROLE");

    bytes32 public constant TECH_OPERATIONS_ROLE =
        keccak256("TECH_OPERATIONS_ROLE");
    bytes32 public constant POLICY_OPERATIONS_ROLE =
        keccak256("POLICY_OPERATIONS_ROLE");
    bytes32 public constant TREASURY_OPERATIONS_ROLE =
        keccak256("TREASURY_OPERATIONS_ROLE");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    bytes32 public constant BLOCKLIST_MANAGER_ROLE =
        keccak256("BLOCKLIST_MANAGER_ROLE");
    bytes32 public constant BLOCKLISTED_ROLE = keccak256("BLOCKLISTED_ROLE");

    bytes32 public constant CITADEL_MINTER_ROLE =
        keccak256("CITADEL_MINTER_ROLE");

    uint256 public constant ONE = 1 ether;

    // ==================
    // ===== Actors =====
    // ==================

    address immutable governance = getAddress("governance");
    address immutable techOps = getAddress("techOps");
    address immutable policyOps = getAddress("policyOps");
    address immutable guardian = getAddress("guardian");
    address immutable keeper = getAddress("keeper");
    address immutable treasuryVault = getAddress("treasuryVault");
    address immutable treasuryOps = getAddress("treasuryOps");

    address immutable citadelTree = getAddress("citadelTree");

    address immutable rando = getAddress("rando");

    address immutable whale = getAddress("whale");
    address immutable shrimp = getAddress("shrimp");
    address immutable shark = getAddress("shark");

    address immutable xCitadelStrategy_address = getAddress("xCitadelStrategy");

    address constant wbtc_address = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant weth_address = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant cvx_address = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address constant renBTC_address =
        0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
    address constant ibBTC_address = 0xc4E15973E6fF2A35cC804c2CF9D2a1b817a8b40F;
    address constant frax_address = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address constant ust_address = 0xa693B19d2931d498c5B318dF961919BB4aee87a5; // UST(Wormhole)
    address constant usdc_address = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant badger_address =
        0x3472A5A71965499acd81997a54BBA8D852C6E53d;
    address constant bveCVX_address =
        0xfd05D3C7fe2924020620A8bE4961bBaA747e6305;

    IERC20 wbtc = IERC20(wbtc_address);
    IERC20 weth = IERC20(weth_address);
    IERC20 cvx = IERC20(cvx_address);
    IERC20 renBTC = IERC20(renBTC_address);
    IERC20 ibBTC = IERC20(ibBTC_address);
    IERC20 frax = IERC20(frax_address);
    IERC20 ust = IERC20(ust_address);
    IERC20 usdc = IERC20(usdc_address);
    IERC20 badger = IERC20(badger_address);
    IERC20 bveCVX = IERC20(bveCVX_address);

    GlobalAccessControl gac = new GlobalAccessControl();

    CitadelToken citadel = new CitadelToken();
    StakedCitadel xCitadel = new StakedCitadel();
    BrickedStrategy xCitadel_strategy = new BrickedStrategy();
    StakedCitadelVester xCitadelVester = new StakedCitadelVester();
    IStakedCitadelLocker xCitadelLocker =
        IStakedCitadelLocker(deployCode(lockerArtifact));

    SupplySchedule schedule = new SupplySchedule();
    CitadelMinter citadelMinter = new CitadelMinter();

    KnightingRound knightingRound = new KnightingRound();
    KnightingRoundWithEth knightingRoundWithEth = new KnightingRoundWithEth();
    KnightingRoundGuestlist guestList = new KnightingRoundGuestlist();

    IMedianOracle medianOracleWbtc =
        IMedianOracle(
            deployCode(medianOracleArtifact, abi.encode(1 days, 0, 1))
        );
    IMedianOracle medianOracleCvx =
        IMedianOracle(
            deployCode(medianOracleArtifact, abi.encode(1 days, 0, 1))
        );
    IMedianOracle medianOracleBadger =
        IMedianOracle(
            deployCode(medianOracleArtifact, abi.encode(1 days, 0, 1))
        );

    Funding fundingWbtc = new Funding();
    Funding fundingCvx = new Funding();

    struct KnightingRoundParams {
        uint256 start;
        uint256 duration;
        uint256 citadelWbtcPrice;
        uint256 tokenInLimit;
    }

    KnightingRoundParams knightingRoundParams;
    KnightingRoundParams knightingRoundWithEthParams;

    function getSelector(string memory _func) public pure returns (bytes4) {
        return bytes4(keccak256(bytes(_func)));
    }

    function setUp() public virtual {
        // Labels
        vm.label(address(this), "this");

        vm.label(governance, "governance");
        vm.label(policyOps, "policyOps");
        vm.label(keeper, "keeper");
        vm.label(guardian, "guardian");
        vm.label(treasuryVault, "treasuryVault");

        vm.label(rando, "rando");

        vm.label(address(knightingRound), "knightingRound");
        vm.label(address(knightingRoundWithEth), "knightingRoundWithEth");
        vm.label(address(guestList), "guestList");
        vm.label(address(schedule), "schedule");
        vm.label(address(gac), "gac");

        vm.label(wbtc_address, "wbtc");
        vm.label(cvx_address, "cvx");
        vm.label(weth_address, "weth");

        vm.label(whale, "whale"); // whale attempts large token actions, testing upper bounds
        vm.label(shrimp, "shrimp"); // shrimp attempts small token actions, testing lower bounds
        vm.label(shark, "shark"); // shark attempts malicious actions

        // Initialization
        vm.startPrank(governance);
        gac.initialize(governance);

        uint256[4] memory xCitadelFees = [
            uint256(0),
            uint256(0),
            uint256(0),
            uint256(0)
        ];

        citadel.initialize("Citadel", "CTDL", address(gac));
        xCitadel.initialize(
            address(citadel),
            address(governance),
            address(keeper),
            address(guardian),
            address(treasuryVault),
            address(techOps),
            address(citadelTree),
            address(xCitadelVester),
            "Staked Citadel",
            "xCTDL",
            xCitadelFees
        );

        xCitadel_strategy.initialize(address(xCitadel), address(citadel));

        xCitadel.setStrategy(address(xCitadel_strategy));

        xCitadelVester.initialize(
            address(gac),
            address(citadel),
            address(xCitadel)
        );
        xCitadelLocker.initialize(
            address(xCitadel),
            address(gac),
            "Vote Locked xCitadel",
            "vlCTDL"
        );

        xCitadelLocker.addReward(
            address(xCitadel),
            address(citadelMinter),
            false
        );

        schedule.initialize(address(gac));
        citadelMinter.initialize(
            address(gac),
            address(citadel),
            address(xCitadel),
            address(xCitadelLocker),
            address(schedule)
        );

        // Knighting Round
        knightingRoundParams = KnightingRoundParams({
            start: block.timestamp + 100,
            duration: 7 days,
            citadelWbtcPrice: 21e18, // 21 xCTDL per wBTC
            tokenInLimit: 100e8 // 100 wBTC
        });

        knightingRoundWithEthParams = KnightingRoundParams({
            start: block.timestamp + 100,
            duration: 7 days,
            citadelWbtcPrice: 21e18, // 21 xCTDL per ETH
            tokenInLimit: 100e18 // 100 ETH
        });

        guestList.initialize(address(gac));

        knightingRound.initialize(
            address(gac),
            address(xCitadel),
            address(wbtc),
            knightingRoundParams.start,
            knightingRoundParams.duration,
            knightingRoundParams.citadelWbtcPrice,
            address(governance),
            address(guestList),
            knightingRoundParams.tokenInLimit
        );

        knightingRoundWithEth.initialize(
            address(gac),
            address(xCitadel),
            address(weth),
            knightingRoundWithEthParams.start,
            knightingRoundWithEthParams.duration,
            knightingRoundWithEthParams.citadelWbtcPrice,
            address(governance),
            address(guestList),
            knightingRoundWithEthParams.tokenInLimit
        );
        vm.stopPrank();

        // Oracle
        medianOracleWbtc.addProvider(keeper);
        medianOracleCvx.addProvider(keeper);
        medianOracleBadger.addProvider(keeper);

        // Funding
        fundingWbtc.initialize(
            address(gac),
            address(citadel),
            address(wbtc),
            address(xCitadel),
            treasuryVault,
            address(medianOracleWbtc),
            100e8
        );
        fundingCvx.initialize(
            address(gac),
            address(citadel),
            address(cvx),
            address(xCitadel),
            treasuryVault,
            address(medianOracleCvx),
            100000e18
        );

        // Set test epoch rates
        vm.startPrank(governance);
        schedule.setEpochRate(0, 593962000000000000000000 / schedule.epochLength());
        schedule.setEpochRate(1, 591445000000000000000000 / schedule.epochLength());
        schedule.setEpochRate(2, 585021000000000000000000 / schedule.epochLength());
        schedule.setEpochRate(3, 574138000000000000000000 / schedule.epochLength());
        schedule.setEpochRate(4, 558275000000000000000000 / schedule.epochLength());
        schedule.setEpochRate(5, 536986000000000000000000 / schedule.epochLength());

        // Grant roles
        gac.grantRole(CONTRACT_GOVERNANCE_ROLE, governance);
        gac.grantRole(TREASURY_GOVERNANCE_ROLE, treasuryVault);

        gac.grantRole(TECH_OPERATIONS_ROLE, techOps);
        gac.grantRole(TREASURY_OPERATIONS_ROLE, treasuryOps);
        gac.grantRole(POLICY_OPERATIONS_ROLE, policyOps);

        gac.grantRole(CITADEL_MINTER_ROLE, address(citadelMinter));
        gac.grantRole(CITADEL_MINTER_ROLE, governance); // To handle initial supply, remove atomically.

        gac.grantRole(PAUSER_ROLE, guardian);
        gac.grantRole(UNPAUSER_ROLE, techOps);

        gac.grantRole(KEEPER_ROLE, keeper);
        vm.stopPrank();

        // Deposit initial assets to users
        erc20utils.forceMintTo(whale, wbtc_address, 1000e8);
        erc20utils.forceMintTo(shrimp, wbtc_address, 10e8);
        erc20utils.forceMintTo(shark, wbtc_address, 100e8);
        erc20utils.forceMintTo(whale, cvx_address, 1000000e18);
        erc20utils.forceMintTo(shrimp, cvx_address, 1000e18);
        erc20utils.forceMintTo(shark, cvx_address, 10000e18);

        vm.deal(whale, 1000 ether);
        vm.deal(shrimp, 10 ether);
        vm.deal(shark, 100 ether);

        // Setup balance tracking
        comparator = new SnapshotComparator();

        uint256 numAddressesToTrack = 8;
        address[] memory accounts_to_track = new address[](numAddressesToTrack);
        string[] memory accounts_to_track_names = new string[](
            numAddressesToTrack
        );

        accounts_to_track[0] = whale;
        accounts_to_track_names[0] = "whale";

        accounts_to_track[1] = shrimp;
        accounts_to_track_names[1] = "shrimp";

        accounts_to_track[2] = shark;
        accounts_to_track_names[2] = "shark";

        accounts_to_track[3] = address(knightingRound);
        accounts_to_track_names[3] = "knightingRound";

        accounts_to_track[4] = address(fundingCvx);
        accounts_to_track_names[4] = "fundingCvx";

        accounts_to_track[5] = address(fundingWbtc);
        accounts_to_track_names[5] = "fundingWbtc";

        accounts_to_track[6] = treasuryVault;
        accounts_to_track_names[6] = "treasuryVault";

        accounts_to_track[7] = address(knightingRoundWithEth);
        accounts_to_track_names[7] = "knightingRoundWithEth";

        // Track balances for all tokens + entities
        for (uint256 i = 0; i < numAddressesToTrack; i++) {
            // wBTC
            string memory wbtc_key = concatenate(
                concatenate("wbtc.balanceOf(", accounts_to_track_names[i]),
                ")"
            );
            comparator.addCall(
                wbtc_key,
                wbtc_address,
                abi.encodeWithSignature(
                    "balanceOf(address)",
                    accounts_to_track[i]
                )
            );

            string memory weth_key = concatenate(
                concatenate("weth.balanceOf(", accounts_to_track_names[i]),
                ")"
            );
            comparator.addCall(
                weth_key,
                weth_address,
                abi.encodeWithSignature(
                    "balanceOf(address)",
                    accounts_to_track[i]
                )
            );

            // Citadel
            string memory citadel_key = concatenate(
                concatenate("citadel.balanceOf(", accounts_to_track_names[i]),
                ")"
            );
            comparator.addCall(
                citadel_key,
                address(citadel),
                abi.encodeWithSignature(
                    "balanceOf(address)",
                    accounts_to_track[i]
                )
            );

            // CVX
            string memory cvx_key = concatenate(
                concatenate("cvx.balanceOf(", accounts_to_track_names[i]),
                ")"
            );
            comparator.addCall(
                cvx_key,
                cvx_address,
                abi.encodeWithSignature(
                    "balanceOf(address)",
                    accounts_to_track[i]
                )
            );

            // xCitadel
            string memory xcitadel_key = concatenate(
                concatenate("xCitadel.balanceOf(", accounts_to_track_names[i]),
                ")"
            );
            comparator.addCall(
                xcitadel_key,
                address(xCitadel),
                abi.encodeWithSignature(
                    "balanceOf(address)",
                    accounts_to_track[i]
                )
            );

            // Knighting Round Purchases
            string memory knighting_round_key = concatenate(
                concatenate(
                    "knightingRound.boughtAmounts(",
                    accounts_to_track_names[i]
                ),
                ")"
            );
            comparator.addCall(
                knighting_round_key,
                address(knightingRound),
                abi.encodeWithSignature(
                    "boughtAmounts(address)",
                    accounts_to_track[i]
                )
            );

            // Knighting Round with Eth Purchases
            string memory knighting_round_weth_key = concatenate(
                concatenate(
                    "knightingRoundWithEth.boughtAmounts(",
                    accounts_to_track_names[i]
                ),
                ")"
            );
            comparator.addCall(
                knighting_round_weth_key,
                address(knightingRoundWithEth),
                abi.encodeWithSignature(
                    "boughtAmounts(address)",
                    accounts_to_track[i]
                )
            );
        }

        comparator.addCall(
            "citadel.totalSupply()",
            address(citadel),
            abi.encodeWithSignature("totalSupply()")
        );

        comparator.addCall(
            "xCitadel.totalSupply()",
            address(xCitadel),
            abi.encodeWithSignature("totalSupply()")
        );

        comparator.addCall(
            "xCitadel.getPricePerFullShare()",
            address(xCitadel),
            abi.encodeWithSignature("getPricePerFullShare()")
        );
    }

    // @dev simple simulation of knighting round, in order to advance next stages in a 'realistic' manner
    function _knightingRoundSim() internal {
        bytes32[] memory emptyProof = new bytes32[](1);

        // Move to knighting round start
        vm.warp(knightingRound.saleStart());

        // Shrimp BTC
        vm.startPrank(shrimp);
        wbtc.approve(address(knightingRound), wbtc.balanceOf(shrimp));
        weth.approve(address(knightingRound), address(shrimp).balance);

        knightingRound.buy(wbtc.balanceOf(shrimp) / 2, 0, emptyProof);

        //Shrimp ETH
        knightingRoundWithEth.buyEth{value: address(shrimp).balance / 2}(
            0,
            emptyProof
        );

        vm.stopPrank();

        // Whale BTC
        vm.startPrank(whale);
        wbtc.approve(address(knightingRound), wbtc.balanceOf(whale));
        weth.approve(address(knightingRound), address(whale).balance);

        knightingRound.buy(wbtc.balanceOf(whale) / 2, 0, emptyProof);

        //Whale ETH
        knightingRoundWithEth.buyEth{value: address(whale).balance / 2}(
            0,
            emptyProof
        );

        vm.stopPrank();
        // Knighting round concludes...
        uint256 timeTillEnd = knightingRoundParams.start +
            knightingRoundParams.duration -
            block.timestamp;
        vm.warp(timeTillEnd);
    }

    // @dev run 'launch' multisend operation as a series of calls.
    function _atomicLaunchSim() internal {
        /*
            Prepare for launch (in prod, atomicly via multisend):
            - Mint initial Citadel based on knighting round assets raised
            - Send 60% to knighting round for distribution
            - finalize() KR to get assets
            - LP with 15% of citadel supply + wBTC amount as per initial price
            - Send 25% remaining to treasury vault
            - Initialize and open funding contracts

            [Citadel now has an open market and funding can commence!]
        */

        vm.startPrank(governance);

        uint256 citadelBoughtWbtc = knightingRound.totalTokenOutBought();
        uint256 citadelBoughtWithEth = knightingRoundWithEth
            .totalTokenOutBought();
        uint256 citadelBought = citadelBoughtWbtc + citadelBoughtWithEth;
        uint256 initialSupply = (citadelBought * 1666666666666666667) / 1e18; // Amount bought = 60% of initial supply, therefore total citadel ~= 1.67 amount bought.

        citadel.mint(governance, initialSupply);
        citadel.approve(
            address(xCitadel),
            citadelBought + citadelBoughtWithEth
        );
        xCitadel.depositFor(address(knightingRound), citadelBought);
        xCitadel.depositFor(
            address(knightingRoundWithEth),
            citadelBoughtWithEth
        );
        uint256 remainingSupply = initialSupply - citadelBought - 1e18; // one coin for seeding xCitadel

        citadel.approve(address(xCitadel), 1e18);
        xCitadel.deposit(1e18);

        // uint256 toLiquidity = (remainingSupply * 4e17) / 1e18; // 15% of total, or 40% of remaining 40% (not used)
        uint256 toTreasury = (remainingSupply * 6e17) / 1e18; // 25% of total, or 60% of remaining 40%

        // TODO: Create curve pool and add liquidity

        citadel.transfer(treasuryVault, toTreasury);

        // Transfer liquidity and remaining assets to treasury
        cvx.transfer(treasuryVault, cvx.balanceOf(governance));
        wbtc.transfer(treasuryVault, wbtc.balanceOf(governance));

        // Set first minting EPOCHS
        gac.revokeRole(CITADEL_MINTER_ROLE, governance); // Remove admin mint, only CitadelMinter rules can mint now

        knightingRound.finalize();
        vm.stopPrank();

        // In a second TX, set the rest of minting epochs in batches, as is possible with gas costs
    }
}
