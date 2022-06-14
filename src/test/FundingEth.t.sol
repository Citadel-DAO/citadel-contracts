// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import {Funding} from "../Funding.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {MedianOracle} from "../oracles/MedianOracle.sol";
import {FundingWithEth} from "../FundingWithEth.sol";
import {IERC20} from "../interfaces/erc20/IERC20.sol";

contract FundingEthTest is BaseFixture {
    using FixedPointMathLib for uint256;

    event Deposit(
        address indexed buyer,
        uint256 assetIn,
        uint256 citadelOutValue
    );

    FundingWithEth fundingEth = new FundingWithEth();
    MedianOracle medianOracleEth =
        new MedianOracle(1 days, 0, 1, [0, type(uint256).max]);

    function setUp() public override {
        BaseFixture.setUp();
        fundingEth.initialize(
            address(gac),
            address(citadel),
            address(weth),
            address(xCitadel),
            treasuryVault,
            address(medianOracleEth),
            100000e18
        );
    }

    function testFundingDepositEth() public {
        uint256 assetAmountIn = 1e18;

        vm.prank(address(governance));
        fundingEth.setDiscountLimits(0, 9999);

        vm.prank(address(policyOps));
        fundingEth.setDiscount(2000); // set discount

        medianOracleEth.addProvider(keeper);
        vm.startPrank(keeper);
        medianOracleEth.pushReport(1000);
        fundingEth.updateCitadelPerAsset();
        vm.stopPrank();

        uint256 citadelAmountOutExpected = fundingEth.getAmountOut(
            assetAmountIn
        );
        vm.prank(governance);
        citadel.mint(address(fundingEth), citadelAmountOutExpected); // fundingContract should have citadel to transfer to user

        vm.deal(shrimp, 1e18); // give some ether to shrimp
        assertEq(shrimp.balance, 1e18);

        uint256 fundingEthCitadelBefore = citadel.balanceOf(
            address(fundingEth)
        );
        uint256 treasuryVaultBalanceBefore = treasuryVault.balance;
        uint256 userBalanceBefore = shrimp.balance;
        uint256 userxCitadelBefore = xCitadel.balanceOf(shrimp);

        vm.expectEmit(true, true, true, true);
        emit Deposit(shrimp, assetAmountIn, citadelAmountOutExpected);
        vm.prank(shrimp);
        uint256 citadelAmountOut = fundingEth.depositEth{value: assetAmountIn}(
            0
        );

        uint256 fundingEthCitadelAfter = citadel.balanceOf(address(fundingEth));
        uint256 treasuryVaultBalanceAfter = treasuryVault.balance;
        uint256 userBalanceAfter = shrimp.balance;
        uint256 userxCitadelAfter = xCitadel.balanceOf(shrimp);

        assertEq(citadelAmountOut, citadelAmountOutExpected);

        assertEq(
            fundingEthCitadelBefore - fundingEthCitadelAfter,
            citadelAmountOutExpected
        );
        assertEq(
            userxCitadelAfter - userxCitadelBefore,
            citadelAmountOutExpected
        );
        assertEq(
            treasuryVaultBalanceAfter - treasuryVaultBalanceBefore,
            assetAmountIn
        );
        assertEq(userBalanceBefore - userBalanceAfter, assetAmountIn);
    }
}
