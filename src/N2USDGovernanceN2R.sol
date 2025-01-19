// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./N2R.sol";
import "./N2USD.sol";

contract N2USDGovernanceN2R is Ownable, ReentrancyGuard, AccessControl {

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

    N2R private n2r;
    N2USD private n2usd;
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

    constructor(N2USD _n2usd, N2R _n2r) Ownable(msg.sender) {
        n2usd = _n2usd;
        n2r = _n2r;
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(GOVERNOR_ROLE, msg.sender);
    }

    function addCollateralToken(IERC20 collateralContract) external nonReentrant {
        require(hasRole(GOVERNOR_ROLE, _msgSender()), "Not Allowed");
        rsvList[reserveCount].colToken = collateralContract;
        reserveCount++;
    }

    function setReserveContract(address _reserveContract) external nonReentrant {
        require(hasRole(GOVERNOR_ROLE, _msgSender()), "Not Allowed");
        reserveContract = _reserveContract;
    }

    function setN2RTokenPrice(uint256 marketCap) external nonReentrant {
        require(hasRole(GOVERNOR_ROLE, _msgSender()), "Not Allowed");
        uint256 n2rSupply = n2r.totalSupply();
        uint256 n2rPrice = marketCap/n2rSupply;
        unstableCollateralPrice = n2rPrice;
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

    function validatePeg() external nonReentrant {
        require(hasRole(GOVERNOR_ROLE, _msgSender()), "Not Allowed");
        n2usdSupply = n2usd.totalSupply();
        bool result = collateralRebalancing();

        if(result == true) {
            uint256 rawCollateralValue = (stableCollateralAmount*1e18) + (unstableCollateralAmount*unstableCollateralPrice);
            uint256 collateralValue = rawCollateralValue*WEI_VALUE;

            if(collateralValue < n2usdSupply) {
                uint256 supplyChange = n2usdSupply - collateralValue;
                uint256 burnAmount = (supplyChange/unstableCollateralPrice)*WEI_VALUE;
                n2r.burn(burnAmount);
                _supplyChanges[supplyChangeCount] = SupChange("burn", supplyChange, block.timestamp, block.number);
                supplyChangeCount++;
                emit RepegAction(block.timestamp, supplyChange);
            } else if(collateralValue > n2usdSupply) {
                uint256 supplyChange = collateralValue - n2usdSupply;
                n2r.mint(supplyChange);
                _supplyChanges[supplyChangeCount] = SupChange("mint", supplyChange, block.timestamp, block.number);
                supplyChangeCount++;
                emit RepegAction(block.timestamp, supplyChange);
            }
            n2usdSupply = collateralValue;
        }
    }

    function withdraw(uint256 _amount) external nonReentrant {
        require(hasRole(GOVERNOR_ROLE, _msgSender()), "Not Allowed");
        n2usd.transfer(address(msg.sender), _amount);
        emit Withdraw(block.timestamp, _amount);
    }

    function withdrawN2R(uint256 _amount) external nonReentrant {
        require(hasRole(GOVERNOR_ROLE, _msgSender()), "Not Allowed");
        n2r.transfer(address(msg.sender), _amount);
        emit Withdraw(block.timestamp, _amount);
    }

}