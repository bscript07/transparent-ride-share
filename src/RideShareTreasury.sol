// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// Custom errors to reduce gas and improve clarity
error NotAdmin();
error NotOwner();
error AlreadyClaimed();
error InitializationFailed();
error OnlyOwnerCanFund();
error NotEnoughETH();
error InvalidSignature();
error InvalidPrice();
error InsufficientBalance();
error VoucherExpired();

contract RideShareTreasury is EIP712Upgradeable, ReentrancyGuardUpgradeable {

    // The address authorized to sign vouchers and fund the contract
    address public owner;

    // Admin who deploys and manages proxy upgrades
    address public admin;

    // Chainlink ETH/USD price feed address
    address public priceFeed;

    // Type hash for the EIP-712 TripVoucher struct
    bytes32 public constant TRIP_VOUCHER_TYPEHASH =
        keccak256("TripVoucher(address driver,uint256 tripId,uint256 usdCents,uint256 expiry)");

    // Keeps track of whether a driver has already claimed a specific tripId
    mapping(address => mapping(uint256 => bool)) public isClaimed;

    // Events for transparency and off-chain tracking data
    event Funded(address indexed from, uint256 amount);
    event VoucherClaimed(address indexed driver, uint256 tripId, uint256 usdCents, uint256 ethAmount);
    event OwnerWithdrawable(address indexed to, uint256 amount);

    // Restricts function to the contract owner (dispatcher)
    modifier onlyOwner() {
        require(msg.sender == owner, NotOwner());
        _;
    }

    // Restricts function to the contract admin (deployer/upgrade authority)
    modifier onlyAdmin() {
        require(msg.sender == admin, NotAdmin());
        _;
    }

    /// @notice Initializes the upgradeable contract with admin, owner, and priceFeed
    function initialize(address _admin, address _owner, address _priceFeed)
        public
        initializer
    {
        __EIP712_init("Vouchers", "1");
        __ReentrancyGuard_init();
        admin = _admin;
        owner = _owner;
        priceFeed = _priceFeed;
    }

    /// @notice Internal helper to build the EIP-712 typed data hash from the voucher fields
    function _hashTripVoucher(address driver, uint256 tripId, uint256 usdCents, uint256 expiry)
        internal
        view
        returns (bytes32)
    {
        return _hashTypedDataV4(
            keccak256(abi.encode(TRIP_VOUCHER_TYPEHASH, driver, tripId, usdCents, expiry))
        );
    }

    /// @notice Verifies if a given voucher signature is valid and signed by the owner
    function verifySignature(address driver, uint256 tripId, uint256 usdCents, uint256 expiry, bytes memory signature)
        public
        view
        returns (bool)
    {
        bytes32 digest = _hashTripVoucher(driver, tripId, usdCents, expiry);
        address signer = ECDSA.recover(digest, signature);

        require(signer != address(0), InvalidSignature());
        return signer == owner;
    }

    /// @notice Allows the owner to fund the treasury contract with ETH
    function fund() external payable {
        require(msg.sender == owner, OnlyOwnerCanFund());
        require(msg.value > 0, NotEnoughETH());

        emit Funded(msg.sender, msg.value);
    }

    /// @notice Allows a driver to claim a voucher payment in ETH
    function voucherClaim(uint256 tripId, uint256 usdCents, uint256 expiry, bytes calldata signature)
        external
        nonReentrant
    {
        // Ensure voucher hasn't already been claimed by this driver for this trip
        require(!isClaimed[msg.sender][tripId], AlreadyClaimed());

        // Ensure the voucher hasn't expired
        require(block.timestamp <= expiry, VoucherExpired());

        // Check if the signature is valid and issued by the owner
        bool valid = verifySignature(msg.sender, tripId, usdCents, expiry, signature);
        require(valid, InvalidSignature());

        // Get the current ETH/USD price from Chainlink
        AggregatorV3Interface feed = AggregatorV3Interface(priceFeed);
        (, int256 price,,,) = feed.latestRoundData();
        require(price > 0, InvalidPrice());

        // Convert the voucher amount from USD cents to wei
        uint256 amountEth = (usdCents * 1e26) / (uint256(price) * 100);
        require(address(this).balance >= amountEth, NotEnoughETH());

        // Mark this voucher as claimed
        isClaimed[msg.sender][tripId] = true;

        // Transfer ETH to the driver
        payable(msg.sender).transfer(amountEth);

        emit VoucherClaimed(msg.sender, tripId, usdCents, amountEth);
    }

    /// @notice Allows the owner to withdraw unused ETH from the contract
    function ownerWithdraw(uint256 amount) external onlyOwner nonReentrant {
        require(address(this).balance >= amount, InsufficientBalance());

        payable(owner).transfer(amount);

        emit OwnerWithdrawable(owner, amount);
    }
}
