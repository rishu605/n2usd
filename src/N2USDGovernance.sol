// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {N2USD} from "./N2USD.sol";

contract N2USDGovernance is Ownable, ReentrancyGuard, AccessControl {

    using SafeERC20 for ERC20;

    struct SupChange {
        string method;
        uint256 amount;
        uint256 timestamp;
        uint256 blockNumber;
    }

    struct reserveList {
        IERC20 colToken;
    }

    mapping (uint256 => reserveList) public rsvList;

    N2USD private n2usd;
    AggregatorV3Interface private priceOracle;
    address private reserveContract;
    uint256 public n2usdSupply;
    address public dataFeed;
    uint256 public supplyChangeCount;
    uint256 public stableCollateralPrice = 1e18;
    uint256 public stableCollateralAmount;
    uint256 private constant COLLATERAL_PRICE_TO_WEI = 1e10;
    uint256 private constant WEI_VALUE = 1e18;
    uint256 unstableCollateralAmount;
    uint256 unstableCollateralPrice;
    uint256 public reserveCount;

    mapping(uint256 => SupChange) public _supplyChanges;
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    event RepegAction(uint256 time, uint256 amount);
    event Withdraw(uint256 time, uint256 amount);

    constructor(N2USD _n2usd) Ownable(msg.sender) {
        n2usd = _n2usd;
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(GOVERNOR_ROLE, msg.sender);
    }

    function addCollateralToken(IERC20 collateralContract) external nonReentrant {
        require(hasRole(GOVERNOR_ROLE, _msgSender()), "Not Allowed");
        rsvList[reserveCount].colToken = collateralContract;
        reserveCount++;
    }

    function setDataFeedAddress(address contractAddress) external {
        require(hasRole(GOVERNOR_ROLE, _msgSender()), "Not Allowed");
        dataFeed = contractAddress;
        priceOracle = AggregatorV3Interface(dataFeed);
    }

    function fetchCollateralPrice() external nonReentrant {
        require(hasRole(GOVERNOR_ROLE, _msgSender()), "Not Allowed");
        (, int256 price, , , ) = priceOracle.latestRoundData();
        unstableCollateralPrice = uint256(price)*COLLATERAL_PRICE_TO_WEI;
    }

    function setReserveContract(address _reserveContract) external nonReentrant {
        require(hasRole(GOVERNOR_ROLE, _msgSender()), "Not Allowed");
        reserveContract = _reserveContract;
    }

    function collateralRebalancing() internal returns (bool) {
        uint256 stableBalance = rsvList[0].colToken.balanceOf(reserveContract);
        uint256 unstableBalance = rsvList[1].colToken.balanceOf(reserveContract);

        if(stableBalance != stableCollateralAmount) {
            stableCollateralAmount = stableBalance;
        }

        if(unstableBalance != unstableCollateralAmount) {
            unstableCollateralAmount = unstableBalance;
        }

        return true;
    }

    
}