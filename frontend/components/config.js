import { ethers } from "ethers";
import rsvABI from './rsvabi.json';
import n2usdABI from './n2usdabi.json';

const rsvcontract = 'rsv contract address';
const n2usdcontract = 'n2usd contract address';
const rpc = 'https://rpc.ankr.com/polygon_mumbai';
const provider = new ethers.providers.JsonRpcProvider(rpc);
const key = 'key';
const wallet = new ethers.Wallet(key, provider);
const reserves = new ethers.Contract(rsvcontract, rsvABI, wallet);
const n2usd = new ethers.Contract(n2usdcontract, n2usdABI, wallet);

export async function getReserves() {
    const rsvcount = Number((reserves ? await reserves?.reserveLength() : 0).toString());
    const n2dusdformat = (await n2usd.totalSupply()).toString();
    const n2dusdsupply = ethers.utils.formatEther(n2dusdformat)
    let i = 0;
    let rsvamounts = [];
    for (i; i < rsvcount; i++){
        const balance = await reserves.rsvVault(i);
        const getbalance = balance.amount.toString();
        let formatbalance = ethers.utils.formatEther(getbalance)
        rsvamounts.push(formatbalance);
    }
    return { rsvamounts, n2dusdsupply };
}