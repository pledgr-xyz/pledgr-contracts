pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract PledgrUser {
    address public owner;
    address[] receivers; // need to store receivers as array to iterate receiversToPercent
    mapping(address => uint256) receiversToPercent; // receiving address => percentage

    constructor(
        address[] _receivers, // address of receivers
        uint256[] _percentages // percentage each receiver gets of TOTAL payment
    ) public {
        owner = msg.sender;
        updateDistributions(_receivers, _percentages);
    }

    // Receives eth and distributes to receivers
    receive() external payable {
        address payable memory _owner = address(uint160(owner()));
        uint256 memory _sumOfPercentages = 0;

        // Send percentage of msg.value to each receiver
        for (uint256 i = 0; i < receivers.length; i++) {
            address payable memory _receiver = receivers[i];
            uint256 memory _receiverPercent = receiversToPercent[_receiver];
            _sumOfPercentages += receiversToPercent[_receiver]; // Sum percentage distributions each time? -> one less thing in storage (owner and their distribution percentage)
            uint256 memory _amountToSend = msg.value * _receiverPercent;
            (bool sent, bytes memory data) = _receiver.call{
                value: _amountToSend
            }("");

            //Check payment was successful
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

        uint256 memory _remainingPercentage = 1 - _sumOfPercentages;

        // Send remainder to owner
        (sent, data) = _owner.call{value: msg.value * _remainingPercentage}("");
        require(
            sent,
            string(
                abi.encodePacked(
                    "Failed to send ",
                    msg.value * _remainingPercentage,
                    "Ether to owner"
                )
            )
        );
    }

    // If msg.data is not empty
    fallback() external payable {}

    // Updates User's distribution receivers and their percentages
    // Can be called from inside and outside the contract but only by the User
    function updateDistributions(address[] _receivers, uint256[] _percentages)
        public
        onlyOwner
    {
        receivers = _receivers;
        uint256 length = _receivers.length;
        require(_percentages == _receivers.length, "INVALID_INPUT");
        for (uint256 i = 0; i < length; i++) {
            distributionReceivers[receivers[i]] = _percentages[i]; // Allocate receivers and their percentages of each total payment
        }
    }
}
