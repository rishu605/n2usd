// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.28;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract PriceOracle {
    AggregatorV3Interface private priceOracle;
    uint256 public unstableColPrice;
    address public dataFeed;

    function setDataFeedAddress(address contractAddress) external {
        dataFeed = contractAddress;
        priceOracle = AggregatorV3Interface(dataFeed);
    }

    function getLatestPrice() public {
        (, int256 price, , , ) = priceOracle.latestRoundData();
        unstableColPrice = colPriceToWei(price);
    }

    function colPriceToWei(int256 colPrice) internal pure returns(uint256) {
        uint256 priceInWei = uint256(colPrice) * 10**10;
        return priceInWei;
    }
}