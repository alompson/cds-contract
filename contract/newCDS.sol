// SPDX-License-Identifier: GPL-3.0
// Version of compiler
pragma solidity >=0.7.0 <0.9.0;

//contract == new affirmation
contract cds {

    address private _owner;
    uint complexity; //overall complexity of the given source code, given by the average between its Halstead Difficulty metric and Cyclomatic complexity, both calculated offchain

    struct Statement {
        string content;
        bool open;
        uint createdAt;
        uint closesAt;
    }

    //statements[0] is the affirmation, the rest is composed of objections
    Statement[] private statements;
    
    mapping (uint => address) public statementToOwner;  //links statement id to the address that created the statement
    mapping (uint => uint) public statementVoteCount;   //links each statement id to the number of votes it has
    mapping (address => uint) public VoterToStatement;  //links each voter to the statement they voted for

    constructor(string memory cid, uint halstead, uint cyclomatic) payable{
        _owner = msg.sender;
        _calculateComplexity(halstead, cyclomatic);

        //create the main affirmation of the contract instance
        _createStatement(cid);
    }


    //helper functions
    modifier isOwner() {
        require(msg.sender == _owner, "do not own affirmation contract");
        _;
    }

    modifier notOwner() {
        require(msg.sender != _owner, "own main affirmation");
        _;
    }

    //returns true when timer of last statement in the array has ended
    function lastHasEnded() public view returns (bool) {
        return block.timestamp > statements[statements.length-1].closesAt; 
    }

    function _calculateComplexity(uint halstead, uint cyclomatic) private {
        complexity = (halstead + cyclomatic)/2;
    }
    
    function _createStatement(string memory cid) private {
        
        require(msg.value == 5000000000000000000, "To create an affirmation, you should pay 5 ether");
        Statement memory new_statement;
        new_statement.content = cid;
        new_statement.open = true;
        new_statement.createdAt = block.timestamp;
        new_statement.closesAt = _calculateStatementTimespan();
            
        statements.push(new_statement);

        uint id = statements.length - 1;
        statementToOwner[id] = msg.sender; //assigns a owner to each statement
        statementVoteCount[id] = 0; //no votes yet
    }

    function _calculateStatementTimespan() private view returns(uint) {
        //the length of array is used to guarantee that each new statement will have a lower timespan
        uint statementTimespan = block.timestamp + complexity*(1 days)/(statements.length + 1); 
        return statementTimespan;
    }

    //CDS functions


    function createObjection(string memory objection) public notOwner() {
        //For an objection to be created, The last affirmation needs to be within its timer
        require((!lastHasEnded()), "Cannot create objection. Needs to settle previous objection");

        _createStatement(objection);

        uint length = statements.length;
        //when an objection is created, two things must happen:

        //1) Timer of previous affirmation needs to be frozen while the new objection is active. This is implemented by adding the timer of the new objection at the last position to the previous statement timers
        for(uint i = 0; i < length-2; i++) {
            statements[i].closesAt += statements[length-1].closesAt;
        }

        //2) statement.open field of te previous affirmation setted to false
        //since an objection is at least on position [1], (operation statements.length - 2) will always be >= 0
        statements[length - 2].open = false;

    }

    function vote() public{

    }

}
