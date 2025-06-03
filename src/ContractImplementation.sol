// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error NotHR();
error AlreadyClaimed();
error InitializationFailed();
error OnlyDirectorCanFund();
error OnlyDirectorCanWithdraw();
error NotEnoughETH();
error InvalidSignature();
error InvalidPrice();
error InsufficientBalance();
error TransferFailed();
error WithdrawFailed();

contract ContractImplementation is Initializable, EIP712Upgradeable, ReentrancyGuard {
    address public hr;
    address public director;
    address public priceFeed;
    string public departmentName;

    bytes32 public constant PAY_PROOF_TYPEHASH =
        keccak256("PayProof(address employee,uint256 period,uint256 usdAmount)");

    mapping(address => mapping(uint256 => bool)) public isClaimed;

    event Funded(address indexed from, uint256 amount);
    event SalaryClaimed(address indexed employee, uint256 period, uint256 usdAmount, uint256 ethAmount);
    event DirectorWithdrawable(address indexed to, uint256 amount);

    modifier onlyHR() {
        require(msg.sender == hr, NotHR());
        _;
    }

    function initialize(address _hr, address _director, address _priceFeed, string memory _departmentName)
        public
        initializer
    {
        __EIP712_init("Paysalary", "1");
        hr = _hr;
        director = _director;
        priceFeed = _priceFeed;
        departmentName = _departmentName;
    }

    function _hashPayStub(address employee, uint256 period, uint256 usdAmount) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(PAY_PROOF_TYPEHASH, employee, period, usdAmount)));
    }

    function verifySignature(address employee, uint256 period, uint256 usdAmount, bytes memory signature)
        public
        view
        returns (bool)
    {
        bytes32 digest = _hashPayStub(employee, period, usdAmount);
        address signer = ECDSA.recover(digest, signature);

        require(signer != address(0), InvalidSignature());
        return signer == director;
    }

    function fund() external payable {
        require(msg.sender == director, OnlyDirectorCanFund());
        require(msg.value > 0, NotEnoughETH());

        emit Funded(msg.sender, msg.value);
    }

    function salaryClaim(uint256 period, uint256 usdGross, bytes calldata signature) external nonReentrant {
        require(!isClaimed[msg.sender][period], AlreadyClaimed());

        bool valid = verifySignature(msg.sender, period, usdGross, signature);
        require(valid, InvalidSignature());

        AggregatorV3Interface feed = AggregatorV3Interface(priceFeed);
        (, int256 price,,,) = feed.latestRoundData();
        require(price > 0, InvalidPrice());

        uint256 amountEth = (usdGross * 1e26) / (uint256(price) * 100);
        require(address(this).balance >= amountEth, NotEnoughETH());

        isClaimed[msg.sender][period] = true;

        (bool success,) = msg.sender.call{value: amountEth}("");
        require(success, TransferFailed());

        emit SalaryClaimed(msg.sender, period, usdGross, amountEth);
    }

    function directorWithdraw(uint256 amount) external nonReentrant {
        require(msg.sender == director, OnlyDirectorCanWithdraw());
        require(address(this).balance >= amount, InsufficientBalance());

        (bool success,) = director.call{value: amount}("");
        require(success, WithdrawFailed());

        emit DirectorWithdrawable(director, amount);
    }
}
