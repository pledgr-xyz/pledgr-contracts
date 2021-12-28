// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PledgeV1 is Ownable {
    address payable[] receivers; // need to store receivers as array to iterate receiversToPercent
    mapping(address => uint8) receiversToPercent; // receiving address => percentage (0-100)

    constructor(
        address payable[] memory _receivers, // address of receivers
        uint8[] memory _percentages // percentage each receiver gets of TOTAL payment
    ) {
        updateDistributions(_receivers, _percentages);
    }

    // Receives eth and distributes to receivers
    receive() external payable {
        uint8 _sumOfPercentages = 0; // max 100

        // Send percentage of msg.value to each receiver
        for (uint256 i = 0; i < receivers.length; i++) {
            address payable _receiver = receivers[i];
            uint8 _receiverPercent = receiversToPercent[_receiver];
            _sumOfPercentages += receiversToPercent[_receiver]; // Sum percentage distributions each time? -> one less thing in storage (owner and their distribution percentage)
            uint256 _amountToSend = msg.value * 100 / _receiverPercent;

            // Attempt to pay receiver
            (bool sent,) = _receiver.call{
                value: _amountToSend
            }("");

            // Check payment was successful
            require(
                sent,
                string(
                    abi.encodePacked(
                        "Failed to send ",
                        _amountToSend,
                        "Ether to ",
                        _receiver
                    )
                )
            );
        }

        uint256 _remainingPercentage = 100 - _sumOfPercentages;
        uint256 _amountForOwner = msg.value * _remainingPercentage;

        // Send remainder to owner
        (bool ownerSent,) = owner().call{value: _amountForOwner}("");
        require(
            ownerSent,
            string(
                abi.encodePacked(
                    "Failed to send ",
                    _amountForOwner,
                    "Ether to owner"
                )
            )
        );
    }

    // If msg.data is not empty
    fallback() external payable {}

    // Updates User's distribution receivers and their percentages
    // Can be called from inside and outside the contract but only by the User
    function updateDistributions(
        address payable[] memory _receivers,
        uint8[] memory _percentages
    ) public onlyOwner {
        receivers = _receivers;
        require(_percentages.length == _receivers.length, "INVALID_INPUT");
        for (uint256 i = 0; i < _receivers.length; i++) {
            receiversToPercent[receivers[i]] = _percentages[i]; // Allocate receivers and their percentages of each total payment
        }
    }
}
