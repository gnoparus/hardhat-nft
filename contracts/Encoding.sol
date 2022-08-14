// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;

contract Encoding {
    function combineStrings() public pure returns (string memory) {
        //

        return string(abi.encodePacked("Hello ", "world!"));
    }

    function encodeNumber() public pure returns (bytes memory) {
        uint256 num1 = 15;
        return abi.encode(num1);
    }

    function encodePackedNumber() public pure returns (bytes memory) {
        uint8 num1 = 15;
        return abi.encodePacked(num1);
    }

    function encodeString() public pure returns (bytes memory) {
        string memory str1 = "abc123";
        return abi.encode(str1);
    }

    // 0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000066162633132330000000000000000000000000000000000000000000000000000
    function encodePackedString() public pure returns (bytes memory) {
        string memory str1 = "abc123";
        return abi.encodePacked(str1);
    }

    function encodeCastString() public pure returns (bytes memory) {
        string memory str1 = "abc123";
        bytes memory b1 = bytes(str1);
        return b1;
    }

    function decodeString() public pure returns (string memory) {
        string memory str1 = abi.decode(encodeString(), (string));
        return str1;
    }

    function multiEncode() public pure returns (bytes memory) {
        bytes memory b1 = abi.encode("1122", "aabb");
        return b1;
    }

    function multiDecode() public pure returns (string memory, string memory) {
        bytes memory b1 = multiEncode();
        return abi.decode(b1, (string, string));
    }

    function multiEncodePacked() public pure returns (bytes memory) {
        bytes memory b1 = abi.encodePacked("1122", "aabb");
        return b1;
    }

    function multiDecodePacked() public pure returns (string memory, string memory) {
        bytes memory b1 = multiEncodePacked();
        // Revert!!
        return abi.decode(b1, (string, string));
    }

    function multiStringCastPacked() public pure returns (string memory) {
        //
        string memory str1 = string(multiEncodePacked());
        return str1;
    }
}
