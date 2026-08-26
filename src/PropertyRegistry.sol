// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PropertyRegistry {
    struct Property {
        string propertyAddress;
        address owner;
        uint256 price;
    }

    uint256 private nextPropertyId;

    mapping(uint256 => Property) private properties;

    event PropertyRegistered(
        uint256 indexed propertyId,
        string propertyAddress,
        address indexed owner,
        uint256 price
    );

    event OwnershipTransferred(
        uint256 indexed propertyId,
        address indexed previousOwner,
        address indexed newOwner
    );

    function registerProperty(
        string memory _address,
        uint256 _price
    ) external {
        uint256 propertyId = nextPropertyId;

        properties[propertyId] = Property({
            propertyAddress: _address,
            owner: msg.sender,
            price: _price
        });

        nextPropertyId++;

        emit PropertyRegistered(
            propertyId,
            _address,
            msg.sender,
            _price
        );
    }

    function transferOwnership(
        uint256 _propertyId,
        address _newOwner
    ) external {
        Property storage property = properties[_propertyId];

        require(
            property.owner == msg.sender,
            "Only owner can transfer ownership"
        );

        require(
            _newOwner != address(0),
            "Invalid new owner"
        );

        address previousOwner = property.owner;

        property.owner = _newOwner;

        emit OwnershipTransferred(
            _propertyId,
            previousOwner,
            _newOwner
        );
    }

    function getProperty(
        uint256 _propertyId
    )
        external
        view
        returns (
            string memory propertyAddress,
            address owner,
            uint256 price
        )
    {
        Property memory property = properties[_propertyId];

        return (
            property.propertyAddress,
            property.owner,
            property.price
        );
    }
}