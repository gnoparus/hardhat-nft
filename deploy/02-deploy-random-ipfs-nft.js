const { network, ethers, getChainId } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")
const { storeImages, storeTokenMetadata } = require("../utils/UploadToPinata")

const VRF_SUB_FUND_AMOUNT = ethers.utils.parseEther("30")
const imagesLocation = "./images/randomNft"

// const imageUris = [
//     "ipfs://QmUY5BQV9YAXpEJPVo5V17MoGaZfG3Uuh67c1w3cvATZFL",
//     "ipfs://QmTEpQQ6okTGH2TzqT2SRrhMMmr4kc8oD8x9ZqAXJdNuSG",
//     "ipfs://QmYQEXyDtQYYEqjbA1a76dMm7hXzdes2dsayRk9ERhkwEW",
// ]

let tokenUris = [
    "ipfs://QmWVyPvjiqoKUx9zEfQTY8uFiix7pRapD3dnxKSVETvsw4",
    "ipfs://QmZG5QSzja3vDsKCMeHnWts6wRkA9FKENLjtTXmPsdJ9SV",
    "ipfs://QmaLtC1QE1Ja767BLvH2qPojU1JQTqok2S5By6WWqDPcSY",
]

const metadataTemplate = {
    name: "",
    description: "",
    image: "",
    attributes: [
        {
            trait_type: "Cuteness",
            value: 99,
        },
    ],
}

module.exports = async function ({ getNamedAccounts, deployments }) {
    //
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    if (process.env.UPLOAD_TO_PINATA == "true") {
        tokenUris = await handleTokenUris()
    }

    let vrfCoordinatorAddress, subscriptionId

    if (developmentChains.includes(network.name)) {
        vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock", deployer)
        vrfCoordinatorAddress = vrfCoordinatorV2Mock.address
        const txResponse = await vrfCoordinatorV2Mock.createSubscription()
        const txReceipt = await txResponse.wait(1)
        subscriptionId = txReceipt.events[0].args.subId

        await vrfCoordinatorV2Mock.fundSubscription(subscriptionId, VRF_SUB_FUND_AMOUNT)
    } else {
        vrfCoordinatorAddress = networkConfig[chainId]["vrfCoordinatorV2"]
        subscriptionId = networkConfig[chainId]["subscriptionId"]
    }
    console.log(`subscriptionId : ${subscriptionId}`)

    const args = [
        vrfCoordinatorAddress,
        networkConfig[chainId]["gasLane"],
        subscriptionId,
        networkConfig[chainId]["callbackGasLimit"],
        tokenUris,
        networkConfig[chainId]["mintFee"],
    ]

    const randomIpfsNft = await deploy("RandomIpfsNft", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(randomIpfsNft.address, args)
    }
    log("--------------------------------------------")
}

async function handleTokenUris() {
    tokenUris = []

    // Store image in ipfs
    const { responses: imageUploadResponses, files } = await storeImages(imagesLocation)

    // Store meta data in ipfs
    for (imageUploadResponseIndex in imageUploadResponses) {
        let tokenUriMetadata = { ...metadataTemplate }
        tokenUriMetadata.name = files[imageUploadResponseIndex].replace(".png", "")
        tokenUriMetadata.description = `An adorable ${tokenUriMetadata.name} pup`
        tokenUriMetadata.image = `ipfs://${imageUploadResponses[imageUploadResponseIndex].IpfsHash}`
        console.log(`Uploading ${tokenUriMetadata.name}...`)

        const metadataUploadResponse = await storeTokenMetadata(tokenUriMetadata)
        tokenUris.push(`ipfs://${metadataUploadResponse.IpfsHash}`)
    }

    console.log("Token URIs uploaded.")
    console.log(tokenUris)

    return tokenUris
}

module.exports.tags = ["all", "randomIpfs", "main"]
