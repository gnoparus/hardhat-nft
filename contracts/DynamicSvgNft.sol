// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "base64-sol/base64.sol";

contract DynamicSvgNft is ERC721 {
    //
    uint256 private s_tokenCounter;
    string private i_lowImageURI;
    string private i_highImageURI;
    string private constant base64EncodedSvgPrefix = "data:image/svg+xml;base64,";
    AggregatorV3Interface internal immutable i_priceFeed;
    mapping(uint256 => int256) public s_tokenIdToHighValue;

    event CreatedNFT(uint256 indexed tokenId, int256 highValue);

    constructor(
        address priceFeedAddress,
        string memory lowSvg,
        string memory highSvg
    ) ERC721("Dynamic Svg Nft", "DSN") {
        //
        s_tokenCounter = 0;
        i_lowImageURI = svgToImageURI(lowSvg);
        i_highImageURI = svgToImageURI(highSvg);
        i_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function svgToImageURI(string memory svg) public pure returns (string memory) {
        // <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" viewBox="-30 -210 2570 2248">
        //   <g transform="matrix(1 0 0 -1 0 1638)">
        //    <path fill="currentColor" d="M1026 540h445q124 -62 176 -123q55 -62 90.5 -157t46.5 -238h-1071q10 143 47 239q17 48 39 86.5t48 68.5q52 60 179 124zM632 -48h1233q-6 175 -42 301q-37 125 -107 206q-72 82 -196 143q-49 24 -82 46.5t-52.5 45.5t-28 48.5t-8.5 54.5t8 54.5t27.5 49t52.5 46.5 t83 47q60 29 108 63t84 73q147 159 154 520h-1234q3 -132 24 -234t56 -175q17 -37 40.5 -70.5t56.5 -64.5t77 -60.5t101 -58.5q43 -21 73.5 -42t50 -43.5t28.5 -48t9 -56.5q0 -108 -124 -171q-150 -74 -211 -134q-62 -60 -97 -132q-36 -75 -58.5 -175t-25.5 -233zM2041 -171 q0 -26 -9.5 -49t-26 -40t-39.5 -26.5t-49 -9.5h-1334q-26 0 -49 9.5t-39.5 26.5t-26 39.5t-9.5 49.5q0 45 27 77t68 43q5 271 92 445.5t265 263.5q48 24 80 42t48 32q31 27 31 65q0 26 -13.5 48.5t-42.5 38.5l-77 41q-94 50 -165 117t-118.5 155.5t-72.5 202.5t-27 258 q-41 11 -68 43t-27 77q0 26 9.5 49t26 40t39.5 26.5t49 9.5h1334q26 0 49 -9.5t39.5 -26.5t26 -39.5t9.5 -49.5q0 -45 -27.5 -78t-69.5 -42q-3 -140 -25.5 -253.5t-66 -202.5t-109.5 -154.5t-154 -110.5q-51 -26 -83 -45t-47 -33q-30 -26 -30 -62q0 -18 5.5 -33t19.5 -30 t39.5 -30t64.5 -33q190 -86 284.5 -263t101.5 -459q42 -9 69.5 -42t27.5 -78z"/>
        //   </g>
        // </svg>

        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));

        return string(abi.encodePacked(base64EncodedSvgPrefix, svgBase64Encoded));
    }

    function mintNft(int256 highValue) public {
        //
        uint256 counter = s_tokenCounter;
        s_tokenCounter += 1;
        s_tokenIdToHighValue[counter] = highValue;
        _safeMint(_msgSender(), counter);
        emit CreatedNFT(counter, highValue);
    }

    function _baseURI() internal pure override returns (string memory) {
        //
        return "data:application/json;base64,";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        //
        require(_exists(tokenId), "URI Query for nonexistent token");
        string memory imageURI = i_lowImageURI;

        (, int256 price, , , ) = i_priceFeed.latestRoundData();

        if (price > s_tokenIdToHighValue[tokenId]) {
            imageURI = i_highImageURI;
        }

        // data:image/svg+xml;base64,
        // data:application/json;base64,

        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name(),
                                '" , "description":"An NFT that changes based on the Chainlink Feed"',
                                '"attributes": [{"trait_type": "coolness", "value": 100}], "image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}
