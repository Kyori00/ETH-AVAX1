// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* 
For this project, write a smart contract that implements 
the require(), assert() and revert() statements.
*/

contract Marketplace {
    string public tokenName = "iTamCoin";
    string public tokenSymbol = "TC";
    uint8 public tokenDecimals = 18;
    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public itemCount;
    mapping(uint256 => Item) public items;

    struct Item {
        string name;
        uint256 price;
        address seller;
        bool isSold;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ItemListed(uint256 itemId, string name, uint256 price, address seller);
    event ItemBought(uint256 itemId, address buyer);
    event ItemRefunded(uint256 itemId, address buyer);

    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        totalSupply = _initialSupply * 10 ** uint256(tokenDecimals);
        balanceOf[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function listItem(string memory _name, uint256 _price) public {
        require(_price > 0, "Price must be greater than 0");
        itemCount++;
        items[itemCount] = Item(_name, _price, msg.sender, false);
        emit ItemListed(itemCount, _name, _price, msg.sender);
    }

    function buyItem(uint256 _itemId) public {
        Item storage item = items[_itemId];
        if (_itemId <= 0 || _itemId > itemCount) {
            revert("Invalid item ID");
        }
        if (balanceOf[msg.sender] < item.price) {
            revert("Insufficient token balance");
        }
        if (allowance[msg.sender][address(this)] < item.price) {
            revert("Allowance too low");
        }
        if (item.isSold) {
            revert("Item already sold");
        }

        transferFrom(msg.sender, item.seller, item.price);
        item.isSold = true;
        emit ItemBought(_itemId, msg.sender);
    }

    function refundItem(uint256 _itemId) public {
        Item storage item = items[_itemId];
        if (!item.isSold) {
            revert("Item not sold yet");
        }
        if (item.seller != msg.sender) {
            revert("Only the seller can refund the item");
        }

        transferFrom(item.seller, msg.sender, item.price);
        item.isSold = false;
        emit ItemRefunded(_itemId, msg.sender);
    }

    function withdrawAll() public {
        require(msg.sender == owner, "Only the owner can withdraw");
        uint256 balance = balanceOf[address(this)];
        require(balance > 0, "No tokens to withdraw");

        // Ensure the contract's token balance is zero after withdrawal
        balanceOf[address(this)] = 0;
        balanceOf[owner] += balance;

        emit Transfer(address(this), owner, balance);

        // Use assert to confirm the contract balance is zero
        assert(balanceOf[address(this)] == 0);
    }
}
