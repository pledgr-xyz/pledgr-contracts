// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct Payout {
    address payable addr;
    uint8 percent;
}

contract PledgeV1 is Ownable {
    mapping(address => Payout[]) public payouts;

    function distribute(address payable sender) public payable {
        uint8 _sumOfPercentages = 0; // max 100
        uint _valueNorm = msg.value / 100;
        Payout[] memory _payouts = payouts[sender];
        // Send percentage of _value to each receiver
        // 2749 (23832 cum.) gas to iterate over empty array
        for (uint8 i = 0; i < _payouts.length; i++) {
            Payout memory _payout = _payouts[i];
            console.log('here', _payout.addr);

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
        (bool ownerSuccess, ) = sender.call{
            value: (_valueNorm) * (100 - _sumOfPercentages)
        }("");

        require(ownerSuccess, string(abi.encodePacked("TRANSFER FAILED")));
    }


    function addPayout(address _owner, Payout memory _payout) external {
        payouts[_owner].push(_payout);
    }

    function getPayouts(address _owner) external view returns (Payout[] memory) {
        return payouts[_owner];
    }
}
