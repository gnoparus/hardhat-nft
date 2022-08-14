const { networkConfig, developmentChains } = require("../helper-hardhat-config")

const BASE_FEE = ethers.utils.parseEther("0.25")
const GAS_PRICE_LINK = 1e9

const DECIMALS = "18"
const INITIAL_PRICE = ethers.utils.parseEther("2000", "ether")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    const args1 = [BASE_FEE, GAS_PRICE_LINK]
    const args2 = [DECIMALS, INITIAL_PRICE]

    if (developmentChains.includes(network.name)) {
        log("Local network detected. Deploying mocks....")

        await deploy("VRFCoordinatorV2Mock", {
            from: deployer,
            log: true,
            args: args1,
        })

        await deploy("MockV3Aggregator", {
            from: deployer,
            log: true,
            args: args2,
        })

        log("Mocks deployed!!")
        log("----------------------------------------------------")
    }
}

module.exports.tags = ["all", "mocks"]
