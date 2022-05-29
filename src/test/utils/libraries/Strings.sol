// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0 <0.9.0;

library Strings {
    function toString(uint256 value, bool isNegative)
        internal
        pure
        returns (string memory)
    {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits = isNegative ? 1 : 0;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        if (isNegative) {
            buffer[0] = "-";
        }
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        return toString(value, false);
    }
}
