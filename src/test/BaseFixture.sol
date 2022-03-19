// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdCheats} from "forge-std/stdlib.sol";
import {TestUtils} from "./TestUtils.sol";

import {CitadelToken} from "../CitadelToken.sol";
import {CitadelMinter} from "../CitadelMinter.sol";
import {SupplySchedule} from "../SupplySchedule.sol";
import {StakedCitadel} from "../StakedCitadel.sol";
import {GlobalAccessControl} from "../GlobalAccessControl.sol";

contract BaseFixture is DSTest, TestUtils {
    Vm constant vm = Vm(HEVM_ADDRESS);

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

    bytes32 public constant BLOCKLIST_MANAGER_ROLE =
        keccak256("BLOCKLIST_MANAGER_ROLE");
    bytes32 public constant BLOCKLISTED_ROLE = keccak256("BLOCKLISTED_ROLE");

    bytes32 public constant CITADEL_MINTER_ROLE =
        keccak256("CITADEL_MINTER_ROLE");

    // ==================
    // ===== Actors =====
    // ==================

    address immutable governance = getAddress("governance");
    address immutable policyOps = getAddress("policyOps");
    address immutable guardian = getAddress("guardian");
    address immutable keeper = getAddress("keeper");
    address immutable treasuryVault = getAddress("treasuryVault");
    address immutable treasuryOps = getAddress("treasuryOps");

    address immutable rando = getAddress("rando");

    SupplySchedule schedule = new SupplySchedule();
    GlobalAccessControl gac = new GlobalAccessControl();
    CitadelToken citadel = new CitadelToken();
    CitadelMinter citadelMinter = new CitadelMinter();
    StakedCitadel xCitadel = new StakedCitadel();

    function setUp() public virtual {

        gac = new GlobalAccessControl();
        schedule = new SupplySchedule();
        
        citadel = new CitadelToken();
        citadelMinter = new CitadelMinter();
        xCitadel = new StakedCitadel();

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
        citadel.initialize("Citadel", "CTDL", gac);
        schedule.initialize(address(gac));

        citadelMinter.initialize(gac, citadel, xCitadel, address(0), schedule);
        

        // Grant roles
        vm.startPrank(governance);
        gac.grantRole(TREASURY_GOVERNANCE_ROLE, treasuryVault);
        gac.grantRole(TREASURY_OPERATIONS_ROLE, treasuryOps);
        gac.grantRole(POLICY_OPERATIONS_ROLE, policyOps);

        // CitadelMinter = CITADEL_MINTER
        vm.stopPrank();
    }
}
