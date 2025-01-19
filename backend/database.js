const {ethPriceDB} = require("./ethPriceDB.json")
const {n2usdPriceDB} = require("./n2usdPriceDB.json")

const fs = require("fs").promises;

const readDb = async (token) => {
    if(token === "eth") {
        const output = await fs.readFile("./ethPriceDB.json", function(err, data) {
            if(err) {
                console.log(err)
            }
            return Buffer.from(data)
        })

        const priceDB = JSON.parse(output)
        return priceDB
    } else if(token === "n2usd") {
        const output = await fs.readFile("./n2usdPriceDB.json", function(err, data) {
            if(err) {
                console.log(err)
            }
            return Buffer.from(data)
        })

        const priceDB = JSON.parse(output)
        return priceDB
    }
}

const writeDB = async (price, time, lastEntry, token) => {
    let entry = {
        updatePrice: price,
        timedate: time,
        entry: lastEntry + 1
    }

    if(token === "eth") {
        ethPriceDB.push(entry)
        const output = await fs.writeFile("./ethPriceDB.json", JSON.stringify(ethPriceDB), function(err) {
            if(err) {
                console.log(err)
            }
            return "Done"
        })
        return output
    } else if(token === "n2usd") {
        n2usdPriceDB.push(entry)
        const output = await fs.writeFile("./n2usdPriceDB.json", JSON.stringify(n2usdPriceDB), function(err) {
            if(err) {
                console.log(err)
            }
            return "Done"
        })
        return output
    }
}