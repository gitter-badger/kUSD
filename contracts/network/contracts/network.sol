pragma solidity ^0.4.18;

contract Network {
    // Total supply of wei. Must be updated every block and initialized to the correct value.
    uint256 public totalSupplyWei = 1 ether;
    // Reward calculated for the last block. Must be updated every block.
    uint256 public lastBlockReward = 0;
    // Price established by the price oracle for the last block. Must be updated every block.
    uint256 public lastPrice = 0;

    // Voter represents a consensus validator      
    struct Voter {
        uint deposit; // amount at stake
        uint index;
    }

    mapping (address => uint) private genesis; // investors (genesis voters)
    mapping (address => Voter) private voters;
    address[] private voterIndex; 

    // maximum number of voters at one time
    uint public constant MAX_VOTERS = 2;
    // minimum deposit value to participate in the consensus
    uint public minDeposit = 0;

    event LogNewVoter(address indexed addr, uint index, uint deposit);
    event LogDeleteVoter(address indexed addr, uint index);

    function isGenesisVoter(address addr) public view returns (bool isIndeed) {
        return genesis[addr] > 0;
    }

    function isVoter(address addr) public view returns (bool isIndeed) {
        if (voterIndex.length == 0) {
            return false; 
        }
        return (voterIndex[voters[addr].index] == addr);
    }

    function _insertVoter(address addr, uint deposit) private {
        voters[addr].deposit = deposit;
        voters[addr].index = voterIndex.push(addr) - 1;
        LogNewVoter(addr, voters[addr].index, deposit);
    }

    function getVoter(address addr) public view returns (uint deposit, uint index) {
        require(isVoter(addr));
        return (voters[addr].deposit, voters[addr].index);
    }

    function _deleteVoter(address addr) private {
        uint rowToDelete = voters[addr].index;
        address keyToMove = voterIndex[voterIndex.length - 1];
        voterIndex[rowToDelete] = keyToMove;
        voters[keyToMove].index = rowToDelete;
        voterIndex.length--;
        LogDeleteVoter(addr, voters[keyToMove].index);
    }

    function getVoterCount() public view returns (uint count) {
        return voterIndex.length;
    }

    function getVoterAtIndex(uint index) public view returns (address addr) {
        return voterIndex[index];
    }

    function deposit() public payable {
        require(!isVoter(msg.sender));
        if (!isGenesisVoter(msg.sender)) {
            require(voterIndex.length < MAX_VOTERS);
            require(msg.value >= minDeposit);
        } else {
            uint investment = genesis[msg.sender];
            require(msg.value >= investment);
        }

        _insertVoter(msg.sender, msg.value);
    }

    function withdraw() public {
        require(isVoter(msg.sender));

        // withdraw locked money
        msg.sender.transfer(voters[msg.sender].deposit);
        
        _deleteVoter(msg.sender);
    }

    function availability() public view returns (bool available) {
        return voterIndex.length <= MAX_VOTERS;
    }

    function Network() public {
        // @TODO (rgerades) - on creation, set in the genesis 
        // the existing accounts and their balance
        genesis[0xd6e579085c82329c89fca7a9f012be59028ed53f] = 100;
        genesis[0x497dc8a0096cf116e696ba9072516c92383770ed] = 100;
    }
}