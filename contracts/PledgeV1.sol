// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct Payout {
    address payable addr;
    uint8 percent;
}

contract PledgeV1 is Ownable {
    address payable[] public receivers; // need to store receivers as array to iterate receiversToPercent
    mapping(address => uint8) public receiversToPercent; // receiving address => percentage (0-100)

    constructor(Payout[] memory _payouts) {
        if (_payouts.length > 0) {
            setPayouts(_payouts);
        }
    }

    // Receives eth and distributes to receivers
    receive() external payable {
        // 21055 initial gas
        uint8 _sumOfPercentages = 0; // max 100
        uint256 _valueNorm = msg.value / 100;
        // Send percentage of _value to each receiver
        // 2749 (23832 cum.) gas to iterate over empty array
        for (uint8 i = 0; i < receivers.length; i++) {
            // 4670 (28502 cum.) gas to assign this variable
            // 554 gas to execute receivers[i]
            address payable _receiver = receivers[i];
            // 4654 (33066 cum.) gas to assign this variable
            uint8 _receiverPercent = receiversToPercent[_receiver];
            // 820 (33800 cum.) gas to assign
            // uint256 _amountToSend = (_value / 100) * _receiverPercent;

            // Attempt to pay receiver
            // 12464 (46264 cum.) gas
            (bool success, ) = _receiver.call{
                value: (_valueNorm) * _receiverPercent
            }("");
            // Check payment was successful
            // 561 (46825 cum.) gas
            require(success, string(abi.encodePacked("ETH TRANSFER FAILED")));

            // 428 gas (47253 cum.)
            _sumOfPercentages += _receiverPercent; // Sum percentage distributions each time? -> one less thing in storage (owner and their distribution percentage)
        }

        // Send remainder to owner
        // 12363 (59616 cum.) gas
        (bool ownerSuccess, ) = owner().call{
            value: (_valueNorm) * (100 - _sumOfPercentages)
        }("");

        // 279 (59895 cum.) gas
        require(ownerSuccess, string(abi.encodePacked("ETH TRANSFER FAILED")));
    }

    // If msg.data is not empty
    fallback() external payable {}

    // Updates User's distribution receivers and their percentages
    // Can be called from inside and outside the contract but only by the User
    function setPayouts(Payout[] memory _payouts) public onlyOwner {
        receivers = new address payable[](_payouts.length);
        for (uint8 i = 0; i < _payouts.length; i++) {
            Payout memory payout = _payouts[i];
            receivers[i] = payout.addr;
            receiversToPercent[payout.addr] = payout.percent; // Allocate receivers and their percentages of each total payment
        }
    }

    // Set payout percentage for given receiver address. Adds new receiver to payouts if it doesn't already exist
    function setReceiverPercent(address payable _receiver, uint8 percent)
        external
        onlyOwner
    {
        if (receiversToPercent[_receiver] != 0) {
            receiversToPercent[_receiver] = percent;
        } else {
            receivers.push(_receiver);
            receiversToPercent[_receiver] = percent;
        }
    }

    // Bulk update existing payouts
    function updatePayouts(Payout[] calldata _payouts) external onlyOwner {
        for (uint8 i = 0; i < _payouts.length; i++) {
            Payout memory payout = _payouts[i];
            require(
                receiversToPercent[payout.addr] != 0,
                string("Receiver not found")
            );
            this.setReceiverPercent(payout.addr, payout.percent);
        }
    }
}
