// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error RandomIpfsNft__RangeOutOfBounds();
error RandomIpfsNft__NeedMoreEthSent();
error RandomIpfsNft__TransferFailed();

contract RandomIpfsNft is VRFConsumerBaseV2, ERC721URIStorage, Ownable {
    //
    enum Breed {
        PUG,
        SHIBA_INU,
        ST_BERNARD
    }

    event NftRequested(uint256 indexed requestId, address indexed requester);
    event NftMinted(Breed dogBreed, address minter);

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subId;
    uint16 private constant MINIMUM_REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    mapping(uint256 => address) public s_requestIdToSender;

    uint256 public s_tokenCounter;
    uint256 public constant MAX_CHANCE_VALUE = 100;
    string[] internal s_dogTokenUris;
    uint256 internal i_mintFee;

    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subId,
        uint32 _callbackGasLimit,
        string[3] memory _dogTokenUris,
        uint256 _mintFee
    ) VRFConsumerBaseV2(_vrfCoordinator) ERC721("Random IPFS NFT", "RIN") {
        //
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_keyHash = _keyHash;
        i_subId = _subId;
        i_callbackGasLimit = _callbackGasLimit;
        s_dogTokenUris = _dogTokenUris;
        i_mintFee = _mintFee;
    }

    function requestNft() public payable returns (uint256 requestId) {
        //
        if (msg.value < i_mintFee) {
            revert RandomIpfsNft__NeedMoreEthSent();
        }
        requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subId,
            MINIMUM_REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        s_requestIdToSender[requestId] = msg.sender;

        emit NftRequested(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        //
        address nftOwner = s_requestIdToSender[requestId];
        uint256 newTokenId = s_tokenCounter;
        s_tokenCounter++;

        // mod random to 0-99
        uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE;

        Breed dogBreed = getBreedFromModdedRng(moddedRng);
        _safeMint(nftOwner, newTokenId);
        _setTokenURI(newTokenId, s_dogTokenUris[uint256(dogBreed)]);
        emit NftMinted(dogBreed, nftOwner);
    }

    function getBreedFromModdedRng(uint256 moddedRng) public pure returns (Breed) {
        uint256 cummulativeSum = 0;
        uint256[3] memory chanceArray = getChangeArray();

        for (uint256 i = 0; i < chanceArray.length; i++) {
            cummulativeSum += chanceArray[i];
            if (moddedRng < cummulativeSum) {
                return Breed(i);
            }
        }
        revert RandomIpfsNft__RangeOutOfBounds();
    }

    function getChangeArray() public pure returns (uint256[3] memory) {
        //
        return [10, 30, MAX_CHANCE_VALUE];
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert RandomIpfsNft__TransferFailed();
        }
    }

    function getMintFee() public view returns (uint256) {
        return i_mintFee;
    }

    function getDogTokenUris(uint256 index) public view returns (string memory) {
        return s_dogTokenUris[index];
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
