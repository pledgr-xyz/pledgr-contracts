// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct Payout {
    address payable addr;
    uint8 percent;
}

contract PledgeV1 is Ownable {
    Payout[] public payouts; // need to store receivers as array to iterate receiversToPercent

    constructor(Payout[] memory _payouts) {
        setPayouts(_payouts);
    }

    // Receives eth and distributes to receivers
    receive() external payable {
        // 21055 initial gas
        uint8 _sumOfPercentages = 0; // max 100
        uint256 _valueNorm = msg.value / 100;
        // Send percentage of _value to each receiver
        // 2749 (23832 cum.) gas to iterate over empty array
        for (uint8 i = 0; i < payouts.length; i++) {
            Payout memory _payout = payouts[i];

            // Attempt to pay receiver
            // 12464 (46264 cum.) gas
            (bool success, ) = _payout.addr.call{
                value: (_valueNorm) * _payout.percent
            }("");
            // Check payment was successful
            // 561 (46825 cum.) gas
            require(success, string(abi.encodePacked("TRANSFER FAILED")));

            // 428 gas (47253 cum.)
            _sumOfPercentages += _payout.percent; // Sum percentage distributions each time? -> one less thing in storage (owner and their distribution percentage)
        }

        // Send remainder to owner
        // 12363 (59616 cum.) gas
        (bool ownerSuccess, ) = owner().call{
            value: (_valueNorm) * (100 - _sumOfPercentages)
        }("");

        // 279 (59895 cum.) gas
        require(ownerSuccess, string(abi.encodePacked("TRANSFER FAILED")));
    }

    // If msg.data is not empty
    fallback() external payable {}

    // Updates User's distribution receivers and their percentages
    // Can be called from inside and outside the contract but only by the User
    function setPayouts(Payout[] memory _payouts) public onlyOwner {
        delete payouts;
        // payouts = new Payout[](0);
        for (uint8 i = 0; i < _payouts.length; i++) {
            payouts.push(_payouts[i]);
        }
    }

    function setReceiverPercent(
        address payable _receiverAddress,
        uint8 _percent
    ) public {
        for (uint8 i = 0; i < payouts.length; i++) {
            if (payouts[i].addr == _receiverAddress) {
                payouts[i].percent = _percent;
                return;
            }
        }

        payouts.push(Payout({addr: _receiverAddress, percent: _percent}));
    }
}
