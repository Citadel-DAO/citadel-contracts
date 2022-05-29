// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0 <0.9.0;

import {console as console} from "forge-std/console.sol";
import {Math} from "openzeppelin-contracts/utils/math/Math.sol";

enum Alignment {
    LEFT,
    RIGHT
}

library Tabulate {
    // =====================
    // ===== Constants =====
    // =====================

    bytes32 constant SEPARATOR_ROW = "--------------------------------";
    bytes1 constant SEPARATOR_COL = "|";

    bytes32 constant BLANK_SPACES = "                                ";

    bytes32 constant DEFAULT_MASK =
        hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

    // ==================
    // ===== Errors =====
    // ==================

    error EmptyTable();
    error UnequalLengths(
        uint256 valuesLen,
        uint256 widthsLen,
        uint256 alignmentsLen
    );
    error InvalidLengths(uint256 stringLen, uint256 paddedLen);

    // =============================
    // ===== Library functions =====
    // =============================

    function log(string[][] memory _table) internal view {
        uint256[] memory widths = getDefaultWidths(_table);

        log(_table, widths);
    }

    function log(string[][] memory _table, uint256[] memory _widths)
        internal
        view
    {
        Alignment[] memory alignments = getDefaultAlignments(_widths.length);

        log(_table, _widths, alignments);
    }

    function log(string[][] memory _table, Alignment[] memory _alignments)
        internal
        view
    {
        uint256[] memory widths = getDefaultWidths(_table);

        log(_table, widths, _alignments);
    }

    function log(
        string[][] memory _table,
        uint256[] memory _widths,
        Alignment[] memory _alignments
    ) internal view {
        if (_table.length == 0 || _table[0].length == 0) {
            revert EmptyTable();
        }

        uint256 numRows = _table.length;
        uint256 numCols = _table[0].length;

        uint256 totalWidth = 3 * numCols + 1;
        for (uint256 j; j < numCols; ++j) {
            totalWidth += _widths[j];
        }

        string memory separator = formatRowSeparator(totalWidth);
        console.log(separator);

        for (uint256 i; i < numRows; ++i) {
            string[] memory row = _table[i];

            console.log(formatRow(row, _widths, _alignments));
            console.log(separator);
        }
    }

    function formatRow(
        string[] memory _row,
        uint256[] memory _widths,
        Alignment[] memory _alignments
    ) internal pure returns (string memory out_) {
        if (
            _row.length != _widths.length || _row.length != _alignments.length
        ) {
            revert UnequalLengths(
                _row.length,
                _widths.length,
                _alignments.length
            );
        }

        uint256 numCols = _row.length;

        uint256 totalWidth = 3 * numCols + 1;
        for (uint256 j; j < numCols; ++j) {
            totalWidth += _widths[j];
        }

        out_ = new string(totalWidth);
        uint256 offset = 32;

        bytes memory colSeparator = new bytes(3);
        colSeparator[0] = SEPARATOR_COL;
        colSeparator[1] = " ";

        bytes32 colSeparator32 = bytes32(colSeparator);
        assembly {
            mstore(add(out_, offset), colSeparator32)
        }
        offset += 2;

        colSeparator[0] = " ";
        colSeparator[1] = SEPARATOR_COL;
        colSeparator[2] = " ";
        colSeparator32 = bytes32(colSeparator);

        for (uint256 j; j < numCols; ++j) {
            uint256 colWidth = _widths[j];
            if (_alignments[j] == Alignment.LEFT) {
                padRightInPlace(_row[j], colWidth, out_, offset);
            } else {
                padLeftInPlace(_row[j], colWidth, out_, offset);
            }
            offset += colWidth;
            assembly {
                mstore(add(out_, offset), colSeparator32)
            }
            offset += 3;
        }

        colSeparator[0] = " ";
        colSeparator[1] = SEPARATOR_COL;
        colSeparator32 = bytes32(colSeparator);

        assembly {
            mstore(add(out_, offset), colSeparator32)
        }
    }

    function padRight(string memory _in, uint256 _length)
        internal
        pure
        returns (string memory out_)
    {
        out_ = new string(_length);
        padRightInPlace(_in, _length, out_, 32);
    }

    function padLeft(string memory _in, uint256 _length)
        internal
        pure
        returns (string memory out_)
    {
        out_ = new string(_length);
        padLeftInPlace(_in, _length, out_, 32);
    }

    function getDefaultWidths(string[][] memory _table)
        internal
        pure
        returns (uint256[] memory widths_)
    {
        if (_table.length == 0 || _table[0].length == 0) {
            revert EmptyTable();
        }

        uint256 numRows = _table.length;
        uint256 numCols = _table[0].length;

        widths_ = new uint256[](numCols);
        for (uint256 i; i < numRows; ++i) {
            for (uint256 j; j < numCols; ++j) {
                widths_[j] = Math.max(widths_[j], bytes(_table[i][j]).length);
            }
        }
    }

    function getDefaultAlignments(uint256 _numCols)
        internal
        pure
        returns (Alignment[] memory alignments_)
    {
        alignments_ = new Alignment[](_numCols);
        alignments_[0] = Alignment.LEFT;
        for (uint256 j = 1; j < _numCols; ++j) {
            alignments_[j] = Alignment.RIGHT;
        }
    }

    function formatRowSeparator(uint256 _length)
        internal
        pure
        returns (string memory out_)
    {
        out_ = new string(_length);
        for (uint256 i; 32 * i < _length; ++i) {
            uint256 offset = 32 * (i + 1);
            assembly {
                mstore(add(out_, offset), SEPARATOR_ROW)
            }
        }
    }

    // =============================
    // ===== Private functions =====
    // =============================

    function padRightInPlace(
        string memory _in,
        uint256 _length,
        string memory _out,
        uint256 _left
    ) private pure {
        if (bytes(_in).length > _length) {
            revert InvalidLengths(bytes(_in).length, _length);
        }

        for (uint256 i; 32 * i < _length; ++i) {
            bytes32 slot;
            uint256 offset = _left + 32 * i;
            if (32 * i < bytes(_in).length) {
                uint256 offsetIn = 32 * (i + 1);
                assembly {
                    slot := mload(add(_in, offsetIn))
                }
                uint256 remaining = bytes(_in).length - 32 * i;
                if (remaining < 32) {
                    assembly {
                        slot := or(slot, shr(mul(8, remaining), BLANK_SPACES))
                    }
                }
            } else {
                slot = BLANK_SPACES;
            }
            assembly {
                mstore(add(_out, offset), slot)
            }
        }
    }

    function padLeftInPlace(
        string memory _in,
        uint256 _length,
        string memory _out,
        uint256 _left
    ) private pure {
        if (bytes(_in).length > _length) {
            revert InvalidLengths(bytes(_in).length, _length);
        }

        for (uint256 i; 32 * i < _length; ++i) {
            bytes32 slot;
            if (32 * i < bytes(_in).length) {
                uint256 offsetIn = bytes(_in).length - 32 * i;
                assembly {
                    slot := mload(add(_in, offsetIn))
                }
                uint256 remainingIn = bytes(_in).length - 32 * i;
                if (remainingIn < 32) {
                    uint256 shiftBitsInv = 8 * (32 - remainingIn);
                    assembly {
                        slot := and(slot, shr(shiftBitsInv, DEFAULT_MASK))
                        slot := or(
                            slot,
                            shl(sub(256, shiftBitsInv), BLANK_SPACES)
                        )
                    }
                }
            } else {
                slot = BLANK_SPACES;
            }

            uint256 offset = _left + _length - 32 * (i + 1);
            uint256 remaining = _length - 32 * i;
            if (remaining < 32) {
                uint256 shiftBits = 8 * (32 - remaining);
                assembly {
                    let mask := shr(shiftBits, DEFAULT_MASK)
                    let loc := add(_out, offset)
                    mstore(loc, add(mload(loc), and(slot, mask)))
                }
            } else {
                assembly {
                    mstore(add(_out, offset), slot)
                }
            }
        }
    }
}

/*
TODOs:
- Create a single table string combining all the rows
*/
