const {ethers} = require('ethers');
const oracleABI = require("./abi/AggregatorABI.json")
const reserveABI = require("./abi/N2USDReservesABI.json")
const n2usdABI = require("./abi/N2USDABI.json")

const oracleEthAddress = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419"
const reserveEthAddress = "address of the reserve contract"
const n2usdEthAddress = "address of the n2usd contract"

const ethRPC = "https://rpc.ankr.com/eth"
const mumbaiRPC = "https://rpc.ankr.com/polygon_mumbai"

const ethProvider = new ethers.providers.JsonRpcProvider(ethRPC)
const mumbaiProvider = new ethers.providers.JsonRpcProvider(mumbaiRPC)

const key = "your private key"
const walletEth = new ethers.Wallet(key, ethProvider)
const walletMumbai = new ethers.Wallet(key, mumbaiProvider)

const ethOracle = new ethers.Contract(oracleEthAddress, oracleABI, walletEth)
const reserves = new ethers.Contract(reserveEthAddress, reserveABI, walletEth)
const n2usd = new ethers.Contract(n2usdEthAddress, n2usdABI, walletMumbai)

async function getEthPrice() {
    let ethPrice = await ethOracle.latestRoundData().catch((err) => {console.log(err)})
    const latestEth = Number((ethPrice.answer).toString()) / 1e8
    console.log("ETH price: ", latestEth)

    return latestEth
}

async function getN2UsdPrice() {
    let latestEth = await getEthPrice()
    let usdtCollateralRaw = await reserves.rsvVault(0).catch((err) => {console.log(err)})
    let ethCollateralRaw = await reserves.rsvVault(1).catch((err) => {console.log(err)})
    let n2usdSupplyRaw = await n2usd.totalSupply().catch((err) => {console.log(err)})
    let usdtCollateral = Number((usdtCollateralRaw.amount).toString()) /1e18
    let ethCollateral = Number((ethCollateralRaw.amount).toString()) / 1e18
    let n2usdSupply = Number((n2usdSupplyRaw).toString()) / 1e18

    let n2usdPrice = (usdtCollateral*1) + (ethCollateral*latestEth) / n2usdSupply
    
    console.log("N2USD price: ", n2usdPrice)
    console.log("USDT collateral: ", usdtCollateralRaw)
    console.log("ETH collateral: ", ethCollateralRaw)
    
}

module.exports = {
    getEthPrice,
    getN2UsdPrice
}