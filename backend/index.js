const {express} = require('express')
const {cors} = require('cors')
const {getDbData, storeEthPrice, storeN2usdPrice} = require('./interface')

const app = express()

const corsOptions = {
    origin: "*",
    optionSuccessStatus: 200
}
app.use(cors(corsOptions))
app.use(require("body-parser").json())

app.post("/getchartinfo", async (req, res) => {
    const token = req.body.token
    return new Promise((resolve, reject) => {
        getDbData(token).then((response) => {
            res.statusCode = 200
            res.setHeader("Content-Type", "application/json")
            res.setHeader("Cache-Control", "max-age=180000")
            res.end(JSON.stringify(response))
            resolve()
        }).catch(err => {
            res.json(err)
            res.status(405).end()
        })
    })
})

const refreshEthPrice = async () => {
    setInterval(() => {
        storeEthPrice()
    }, 120000)
}

const refreshN2UsdPrice = async () => {
    setInterval(() => {
        storeN2usdPrice()
    }, 120000)
}

const server = app.listen(8081, () => {
    const port = server.address().port
    refreshEthPrice()
    refreshN2UsdPrice()
    console.log("Server started on port: ", port)
})