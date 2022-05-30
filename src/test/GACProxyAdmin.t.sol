pragma solidity 0.8.12;

import {BaseFixture} from "./BaseFixture.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";
import "ds-test/test.sol";
import "forge-std/console.sol";

import "openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {GACProxyAdmin} from "../GACProxyAdmin.sol";
import {KnightingRound} from "../KnightingRound.sol";

contract GACProxyAdminTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }

    function testGacProxyAdmin() public {
        vm.startPrank(governance);

        GACProxyAdmin gacProxyAdmin = new GACProxyAdmin();
        assertEq(address(0), address(gacProxyAdmin.gac()));
        gacProxyAdmin.initialize(address(gac));
        assertEq(address(gac), address(gacProxyAdmin.gac()));

        TransparentUpgradeableProxy currKnightingRound = new TransparentUpgradeableProxy(
                address(knightingRound),
                address(gacProxyAdmin),
                ""
            );

        address knightingRoundImplementation = gacProxyAdmin
            .getProxyImplementation(currKnightingRound);
        assertEq(knightingRoundImplementation, address(knightingRound));

        address gacProxyAdminAddress = gacProxyAdmin.getProxyAdmin(
            currKnightingRound
        );
        assertEq(gacProxyAdminAddress, address(gacProxyAdmin));

        KnightingRound knightingRound2 = new KnightingRound();
        gacProxyAdmin.upgrade(currKnightingRound, address(knightingRound2));

        knightingRoundImplementation = gacProxyAdmin.getProxyImplementation(
            currKnightingRound
        );
        assertEq(knightingRoundImplementation, address(knightingRound2));

        GACProxyAdmin gacProxyAdmin2 = new GACProxyAdmin();
        gacProxyAdmin2.initialize(address(gac));
        gacProxyAdmin.changeProxyAdmin(
            currKnightingRound,
            address(gacProxyAdmin2)
        );

        vm.expectRevert(); // should revert gacProxyAdmin is changed
        gacProxyAdmin.getProxyAdmin(currKnightingRound);

        gacProxyAdminAddress = gacProxyAdmin2.getProxyAdmin(currKnightingRound);
        assertEq(gacProxyAdminAddress, address(gacProxyAdmin2));

        vm.expectRevert(); // should revert gacProxyAdmin is changed
        gacProxyAdmin.getProxyImplementation(currKnightingRound);

        knightingRoundImplementation = gacProxyAdmin2.getProxyImplementation(
            currKnightingRound
        );
        assertEq(knightingRoundImplementation, address(knightingRound2));

        vm.stopPrank();
    }
}
