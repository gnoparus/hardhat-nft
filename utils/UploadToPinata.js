const pinataSdk = require("@pinata/sdk")
const path = require("path")
const fs = require("fs")

const pinataApiKey = process.env.PINATA_API_KEY || ""
const pinataApiSecret = process.env.PINATA_API_SECRET || ""
const pinata = pinataSdk(pinataApiKey, pinataApiSecret)

async function storeImages(imagesFilePath) {
    //
    const fullImagesPath = path.resolve(imagesFilePath)
    const files = fs.readdirSync(fullImagesPath)

    let responses = []
    for (fileIndex in files) {
        const readableStreamForFile = fs.createReadStream(`${fullImagesPath}/${files[fileIndex]}`)
        try {
            const response = await pinata.pinFileToIPFS(readableStreamForFile)
            responses.push(response)
        } catch (err) {
            console.log(err)
        }
    }
    return { responses, files }
}

async function storeTokenMetadata(metadata) {
    //
    try {
        const response = await pinata.pinJSONToIPFS(metadata)
        return response
    } catch (err) {
        console.log(err)
    }
    return null
}

module.exports = { storeImages, storeTokenMetadata }
