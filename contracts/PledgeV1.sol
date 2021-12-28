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
        setPayouts(_payouts);
    }

    function getReceiverPercent(address payable _receiver)
        public
        view
        returns (uint8)
    {
        return receiversToPercent[_receiver];
    }

    // Receives eth and distributes to receivers
    receive() external payable {
        uint8 _sumOfPercentages = 0; // max 100

        // Send percentage of msg.value to each receiver
        for (uint8 i = 0; i < receivers.length; i++) {
            address payable _receiver = receivers[i];
            uint8 _receiverPercent = getReceiverPercent(receivers[i]);
            uint256 _amountToSend = (msg.value / 100) * _receiverPercent;
            // Attempt to pay receiver
            (bool success, ) = _receiver.call{value: _amountToSend}("");
            // Check payment was successful
            require(
                success,
                string(
                    abi.encodePacked(
                        "Failed to send ",
                        _amountToSend,
                        " Ether to ",
                        _receiver
                    )
                )
            );

            _sumOfPercentages += _receiverPercent; // Sum percentage distributions each time? -> one less thing in storage (owner and their distribution percentage)
        }

        uint256 _remainingPercentage = 100 - _sumOfPercentages;
        uint256 _amountForOwner = (msg.value / 100) * _remainingPercentage;

        // Send remainder to owner
        (bool ownerSent, ) = owner().call{value: _amountForOwner}("");
        require(
            ownerSent,
            string(
                abi.encodePacked(
                    "Failed to send ",
                    _amountForOwner,
                    " Ether to owner"
                )
            )
        );
    }

    // If msg.data is not empty
    fallback() external payable {}

    // Updates User's distribution receivers and their percentages
    // Can be called from inside and outside the contract but only by the User
    function setPayouts(Payout[] memory _payouts) public onlyOwner {
        receivers = new address payable[](_payouts.length);
        for (uint8 i = 0; i < _payouts.length; i++) {
            Payout memory payout = _payouts[i];
            receivers.push(payout.addr);
            receiversToPercent[payout.addr] = payout.percent; // Allocate receivers and their percentages of each total payment
        }
    }
}
