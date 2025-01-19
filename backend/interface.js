const {getEthPrice, getN2UsdPrice} = require('./getPrices');
const {readDb, writeDB} = require('./database');
const { write } = require('fs');

const getDbData = async (token) => {
    let fromOutput = await readDb(token).catch((err) => {console.log(err)})
    let chartPrice = []
    let chartTime = []
    let chartEntry = []
    if(fromOutput !== undefined) {
        fromOutput.forEach(element => {
            chartPrice.push(element.updatePrice)
            chartTime.push(element.timedate)
            chartEntry.push(element.entry)
        })
    }

    return {chartPrice, chartTime, chartEntry}
}

const storeEthPrice = async () => {
    const token = "eth"
    let price = await getEthPrice()
    const fetchTime = new Date()
    const time = fetchTime.getHours() + ":" + fetchTime.getMinutes() + ":" + fetchTime.getSeconds()
    const fetchLast = await getDbData(token).catch((err) => {console.log(err)})
    let rawLastEntry = fetchLast.chartEntry
    if(rawLastEntry.length === 0) {
        const lastEntry = 0
        await writeDB(price, time, lastEntry, token).catch((err) => {console.log(err)})
    } else {
        const lastEntry = rawLastEntry[rawLastEntry.length - 1]
        await writeDB(price, time, lastEntry, token).catch((err) => {console.log(err)})
    }
}

const storeN2usdPrice = async () => {
    const token = "n2usd"
    let price = await getN2UsdPrice()
    const fetchTime = new Date()
    const time = fetchTime.getHours() + ":" + fetchTime.getMinutes() + ":" + fetchTime.getSeconds()
    const fetchLast = await getDbData(token).catch((err) => {console.log(err)})
    let rawLastEntry = fetchLast.chartEntry
    if(rawLastEntry.length === 0) {
        const lastEntry = 0
        await writeDB(price, time, lastEntry, token).catch((err) => {console.log(err)})
    } else {
        const lastEntry = rawLastEntry[rawLastEntry.length - 1]
        await writeDB(price, time, lastEntry, token).catch((err) => {console.log(err)})
    }
}

module.exports = {
    getDbData,
    storeEthPrice,
    storeN2usdPrice,
}