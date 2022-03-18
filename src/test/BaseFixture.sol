// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdCheats} from "forge-std/stdlib.sol";
import {TestUtils} from "./TestUtils.sol";

import {SupplySchedule} from "../SupplySchedule.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";

contract BaseFixture is DSTest, TestUtils {
    Vm constant vm = Vm(HEVM_ADDRESS);

    // ==================
    // ===== Actors =====
    // ==================

    address immutable governance = getAddress("governance");
    address immutable policyOps = getAddress("policyOps");
    address immutable guardian = getAddress("guardian");
    address immutable keeper = getAddress("keeper");
    address immutable treasury = getAddress("treasury");

    address immutable rando = getAddress("rando");

    SupplySchedule schedule = new SupplySchedule();
    GlobalAccessControl gac = new GlobalAccessControl();

    function setUp() public virtual {

        schedule = new SupplySchedule();
        gac = new GlobalAccessControl();

        // Labels
        vm.label(address(this), "this");

        vm.label(governance, "governance");
        vm.label(policyOps, "policyOps");
        vm.label(keeper, "keeper");
        vm.label(guardian, "guardian");
        vm.label(treasury, "treasury");

        vm.label(rando, "rando");

        vm.label(address(schedule), "schedule");
        vm.label(address(gac), "gac");

        gac.initialize(governance);
        schedule.initialize(address(gac));
    }
}
