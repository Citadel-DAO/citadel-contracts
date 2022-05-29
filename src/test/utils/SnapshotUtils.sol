// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0 <0.9.0;

import {Vm} from "forge-std/Vm.sol";
import {Multicall3} from "multicall/Multicall3.sol";
import {Strings} from "./libraries/Strings.sol";
import {Tabulate} from "./libraries/Tabulate.sol";
import {console as console} from "forge-std/console.sol";

import {IntervalUint256, IntervalUint256Utils} from "./IntervalUint256.sol";
import {DSTest2} from "./DSTest2.sol";

contract Snapshot {
    mapping(string => uint256) private values;
    mapping(string => bool) public exists;

    error InvalidKey(string key);

    constructor(string[] memory _keys, uint256[] memory _vals) {
        uint256 length = _keys.length;
        for (uint256 i; i < length; ++i) {
            string memory key = _keys[i];
            exists[key] = true;
            values[key] = _vals[i];
        }
    }

    function valOf(string calldata _key) public view returns (uint256 val_) {
        if (exists[_key]) {
            val_ = values[_key];
        } else {
            revert InvalidKey(_key);
        }
    }
}

contract SnapshotManager {
    Vm constant vm_snapshot_manager =
        Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));
    Multicall3 constant MULTICALL =
        Multicall3(0xcA11bde05977b3631167028862bE2a173976CA11);

    string[] public keys;
    mapping(string => bool) public exists;

    Multicall3.Call[] public calls;

    constructor() {
        if (address(MULTICALL).code.length == 0) {
            vm_snapshot_manager.etch(
                address(MULTICALL),
                type(Multicall3).runtimeCode
            );
        }
    }

    function addCall(
        string calldata _key,
        address _target,
        bytes calldata _callData
    ) public {
        if (!exists[_key]) {
            exists[_key] = true;
            keys.push(_key);
            calls.push(Multicall3.Call(_target, _callData));
        }
    }

    function snap() public returns (Snapshot snap_) {
        (, bytes[] memory rdata) = MULTICALL.aggregate(calls);
        uint256 length = rdata.length;

        uint256[] memory vals = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            vals[i] = abi.decode(rdata[i], (uint256));
        }

        snap_ = new Snapshot(keys, vals);
    }
}

contract SnapshotComparator is SnapshotManager {
    Snapshot sCurr;
    Snapshot sPrev;

    constructor() {}

    function diff(
        Snapshot _snap1,
        Snapshot _snap2,
        string memory _key
    ) private view returns (uint256 val_) {
        val_ = _snap1.valOf(_key) - _snap2.valOf(_key);
    }

    function snapPrev() public {
        sPrev = snap();
    }

    function snapCurr() public {
        sCurr = snap();
    }

    function curr(string memory _key) public view returns (uint256 val_) {
        val_ = sCurr.valOf(_key);
    }

    function prev(string memory _key) public view returns (uint256 val_) {
        val_ = sPrev.valOf(_key);
    }

    function diff(string memory _key) public view returns (uint256 val_) {
        val_ = diff(sCurr, sPrev, _key);
    }

    function negDiff(string memory _key) public view returns (uint256 val_) {
        val_ = diff(sPrev, sCurr, _key);
    }

    uint256 constant NUM_LOG_COLS = 4;

    function log() external view {
        uint256 maxRows = keys.length;

        string[][] memory table = new string[][](maxRows + 1);
        table[0] = new string[](NUM_LOG_COLS);

        string[] memory cols = table[0];
        cols[0] = "Key";
        cols[1] = "Previous Value";
        cols[2] = "Current Value";
        cols[3] = "Difference";
        uint256 numRows = 1;
        for (uint256 i; i < maxRows; ++i) {
            string memory key = keys[i];
            uint256 numVal1 = prev(key);
            uint256 numVal2 = curr(key);
            console.log(key);
            if (numVal1 != numVal2) {
                table[numRows] = new string[](NUM_LOG_COLS);
                cols = table[numRows];

                cols[0] = key;
                cols[1] = Strings.toString(numVal1);
                cols[2] = Strings.toString(numVal2);
                cols[3] = numVal1 > numVal2
                    ? Strings.toString(negDiff(key), true)
                    : Strings.toString(diff(key));

                ++numRows;
            }
        }

        assembly {
            mstore(table, numRows)
        }

        Tabulate.log(table);
    }
}
