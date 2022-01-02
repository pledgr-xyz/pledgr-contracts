// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PledgeV1.sol";

contract PledgeProxy is Ownable {
    address private pledgeMasterAddr;

    constructor(address _pledgeMasterAddr) {
        pledgeMasterAddr = _pledgeMasterAddr;
    }

    receive() external payable {
        // PledgeV1(pledgeMasterAddr).distribute(payable(owner()), msg.value);
        // (bool success, bytes memory data) = pledgeMasterAddr.call{value: msg.value}(
        //     abi.encodeWithSignature("distribute(address)", payable(owner()))
        // );

        // gas: 198 to assign the above variables (21253 cum.)
        uint8 _sumOfPercentages = 0; // max 100
        uint256 _valueNorm = msg.value / 100;
        // gas: 2149 (23402 cum.)
        // Can save this by initialising it in constructor instead
        PledgeV1 c = PledgeV1(pledgeMasterAddr);
        Payout[] memory _payouts = c.getPayouts(
            owner()
        );

        // Send percentage of _value to each receiver
        // 2749 (23832 cum.) gas to iterate over empty array
        for (uint8 i = 0; i < _payouts.length; i++) {
            Payout memory _payout = _payouts[i];
            console.log("here", _payout.addr);

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

        require(ownerSuccess, string(abi.encodePacked("TRANSFER FAILED")));
    }

    function addPayout(Payout memory _payout) public onlyOwner {
        PledgeV1(pledgeMasterAddr).addPayout(owner(), _payout);
    }
}
