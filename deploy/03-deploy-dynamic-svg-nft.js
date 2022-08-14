const fs = require("fs")
const { network, ethers, getChainId } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

module.exports = async function ({ getNamedAccounts, deployments }) {
    //
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    let ethUsdPriceFeedAddress

    if (developmentChains.includes(network.name)) {
        const ethUsdAggregator = await ethers.getContract("MockV3Aggregator", deployer)
        ethUsdPriceFeedAddress = ethUsdAggregator.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeedAddress"]
    }

    const lowSvg = await fs.readFileSync("./images/dynamicNft/Down.svg", { encoding: "utf8" })
    const highSvg = await fs.readFileSync("./images/dynamicNft/Up.svg", { encoding: "utf8" })

    const args = [ethUsdPriceFeedAddress, lowSvg, highSvg]

    const dynamicSvgNft = await deploy("DynamicSvgNft", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(dynamicSvgNft.address, args)
    }
    log("--------------------------------------------")
}
module.exports.tags = ["all", "dynamicSvgNft", "main"]
