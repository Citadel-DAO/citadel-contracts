pragma solidity 0.8.12;

import "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdCheats} from "forge-std/stdlib.sol";

import {MedianOracle} from "../MedianOracle.sol";

contract TempTest is DSTest, stdCheats {
    Vm constant vm = Vm(HEVM_ADDRESS);

    MedianOracle medianOracle = new MedianOracle(1 days, 0, 1);

    function testMedianOracle() public {
        vm.warp(1 days);

        medianOracle.addProvider(address(this));

        medianOracle.pushReport(1000);

        skip(1 days + 1);

        (uint256 value, bool valid) = medianOracle.getData();
        assertTrue(valid);
    }
}
