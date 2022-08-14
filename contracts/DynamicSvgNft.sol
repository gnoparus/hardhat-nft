// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "base64-sol/base64.sol";

contract DynamicSvgNft is ERC721 {
    //
    uint256 private s_tokenCounter;
    string private i_lowSvg;
    string private i_highSvg;
    string private constant base64EncodedSvgPrefix = "data:image/svg+xml;base64,";

    constructor(string memory lowSvg, string memory highSvg) ERC721("Dynamic Svg Nft", "DSN") {
        //
        s_tokenCounter = 0;
        i_lowSvg = lowSvg;
        i_highSvg = highSvg;
    }

    function svgToImageURI(string memory svg) public pure returns (string memory) {
        //
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));

        return string(abi.encodePacked(base64EncodedSvgPrefix, svgBase64Encoded));
    }

    function mintNft() public {
        //
        _safeMint(_msgSender(), s_tokenCounter);
        s_tokenCounter += 1;
    }
}
