// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract N2USDReserves is Ownable, ReentrancyGuard, AccessControl {

    using SafeERC20 for IERC20;

    uint256 public currentReserveId;
    struct ReserveVault {
        IERC20 collateral;
        uint256 amount;
    }

    mapping(uint256 => ReserveVault) public _rsvVault;

    event Withdraw (uint256 indexed vid, uint256 amount);
    event Deposit (uint256 indexed vid, uint256 amount);

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor() Ownable(msg.sender){
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
    }

    function checkReserveContract(IERC20 _collateral) internal view {
        for(uint256 i = 0; i < currentReserveId; i++) {
            require(_rsvVault[i].collateral != _collateral, "Reserve already exists for this Collateral");
        }
    }

    function addReserveVault(IERC20 _collateral) external  {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Not Allowed");
        checkReserveContract(_collateral);
        _rsvVault[currentReserveId].collateral = _collateral;
        currentReserveId++;
    }

    function depositCollateral(uint256 vid, uint256 amount) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Not Allowed");
        IERC20 reserves = _rsvVault[vid].collateral;
        reserves.safeTransferFrom(address(msg.sender), address(this), amount);
        uint256 currentVaultBalance = _rsvVault[vid].amount;
        _rsvVault[vid].amount = currentVaultBalance + amount;

        emit Deposit(vid, amount);
    }

    function withdrawCollateral(uint256 vid, uint256 amount) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Not Allowed");
        IERC20 reserves = _rsvVault[vid].collateral;
        uint256 currentVaultBalance = _rsvVault[vid].amount;
        if(currentVaultBalance >= amount) {
            reserves.safeTransfer(address(msg.sender), amount);
            _rsvVault[vid].amount = currentVaultBalance - amount;
        }

        emit Withdraw(vid, amount);

    }

}