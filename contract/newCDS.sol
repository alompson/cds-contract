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
    bool private cdsEnded;
    bool private affirmationPassed;
    
    mapping (uint => address) public statementToOwner;  //links statement id to the address that created the statement
    mapping (uint => uint) public statementVoteCount;   //links each statement id to the number of votes it has

    //has to be address => Statement and not address => uint because by default, values are setted to 0, and 0 matters in this application because is the id of the first statement;
    mapping (address => Statement) public voterToStatement;  //links each voter to the statement they voted for
    mapping (address => bool) public hasVoted; 

    event newStatement(string content, uint createdAt, uint closesAt);


    constructor(string memory cid, uint halstead, uint cyclomatic) payable{
        _owner = msg.sender;
        _calculateComplexity(halstead, cyclomatic);

        //create the main affirmation of the contract instance
        _createStatement(cid);
        cdsEnded = false;
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

    modifier cdsOpen() {
        require((cdsEnded == false), "This discussion is settled");
        _;
    }

    function _closeCds() private {
        cdsEnded = true;
    }

    //guarantees ID is valid
    function _idExists(uint id) private view returns (bool) {
        return id < statements.length;
    }

    //returns true when timer of id's statement has ended
    function _hasEnded(uint id) private view returns (bool) {
        return block.timestamp > statements[id].closesAt; 
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
        
        emit newStatement(new_statement.content, new_statement.createdAt, new_statement.closesAt);

    }

    function _calculateStatementTimespan() private view returns(uint) {
        //the length of array is used to guarantee that each new statement will have a lower timespan
        uint statementTimespan = block.timestamp + complexity*(1 days)/(statements.length + 1); 

        return statementTimespan;
    }

    function _hashStatement(Statement memory s) private pure returns (bytes32) {
        //hash using the two fields in a statement that never change, that are content and createdAt
        return keccak256(abi.encode(s.content, s.createdAt)); 
    }

    //used in changeVote
    function _compareStatements(Statement memory a, Statement memory b) private pure returns(bool) {
        return _hashStatement(a) == _hashStatement(b);
    }

    //everytime a debate is settled, the voters of winning statement get a prize
    function _payVotersOfWinningStatement(uint id) private {}

    //when original statement wins, it is registered on blockchain
    function _registerAfirmationOnBlockchain() private {
        affirmationPassed = true;
    }
    function _affirmationBlockedBySdc() private {
        affirmationPassed = false;
    }


    //CDS functions


    function createObjection(string memory objection) public payable notOwner() cdsOpen(){
        //For an objection to be created, The last affirmation needs to be within its timer
        require((!_hasEnded(statements.length-1)), "Cannot create objection on previous closed affirmation");

        _createStatement(objection);

        uint length = statements.length;
        //when an objection is created, two things must happen:

        //1) Timer of previous affirmation needs to be frozen while the new objection is active. This is implemented by adding the timer of the new objection at the last position to the previous statement timers
        for(uint i = 0; i <= length-2; i++) {
            statements[i].closesAt += statements[length-1].closesAt;
        }

        //2) statement.open field of te previous affirmation setted to false
        //since an objection is at least on position [1], (operation statements.length - 2) will always be >= 0
        statements[length - 2].open = false;


        //Also when new objection is created, voters have the option to change their vote

    }

    function vote(uint id) public payable cdsOpen(){
        //statement must be valid
        require ((_idExists(id)), "statement id not valid");

        //Statement needs to be within its timer
        require((!_hasEnded(id)), "statement closed for further votes");
        
        //require person not having voted on statements previously
        require((!hasVoted[msg.sender]), "You already voted");       

        require((msg.value == 1000000000000000000), "To vote you should pay 1 ether"); // owner needs the money to vote

        //Can vote. Update mappings
        hasVoted[msg.sender] = true; //tells the voter already voted
        voterToStatement[msg.sender] = statements[id]; //points user to the statement they voted for
        statementVoteCount[id]++; //statement receives one more vote
    }

    //when called, this function updates the vote of msg.sender to point to the last objection created
    function changeVote(uint previousVoteId) public payable cdsOpen() notOwner(){
        require((hasVoted[msg.sender]), "To change the vote, you should vote on a previous statement");
        require ((_idExists(previousVoteId)), "statement id not valid");

        uint newStatementId = statements.length -1;

        //Last Statement needs to be within its timer
        require((!_hasEnded(newStatementId)), "statement closed for further votes");

        //Confirm the id the person passed is actually the id of the statement they voted for
        require((_compareStatements(voterToStatement[msg.sender], statements[previousVoteId])), "You provided the wrong statement id. provide the id of the statement you voted previously");

        //The person can't change the vote if they already voted for the last statement
        require((!_compareStatements(voterToStatement[msg.sender], statements[newStatementId])), "You already voted for the last objection created");

        //Can change vote. Update mappings
        //remove previous vote
        statementVoteCount[previousVoteId]--;
       
        //add one vote to new statement
        statementVoteCount[newStatementId]++;
        //point to new statement
        voterToStatement[msg.sender] = statements[newStatementId];

    }

    //This should be automatically called when timer of last statement ends. In this implementation, this will be a manual call that any user, contributor or revisor, can perform
    function settleDispute() public cdsOpen(){

        uint length = statements.length;
        //last statement's timer needs to have ended
        require((_hasEnded(length-1)), "Last statement hasn't closed yet");

        if(length == 1) { //There were no objections and affirmation timer ended
        //In this case, affirmation was accepted. Discussion ended.
            _payVotersOfWinningStatement(0);
            _registerAfirmationOnBlockchain();
            _closeCds();

        } else if(length == 2){ //There is just one objection
        //In this case, compare original affirmation with first objection
            if(statementVoteCount[0] > statementVoteCount[1]) {
                //if original affirmation wins, it is registered on blockchain
                _payVotersOfWinningStatement(0);
                _registerAfirmationOnBlockchain();
            } else if(statementVoteCount[0] <= statementVoteCount[1]) {
                //if objection wins, it blocks the affirmation
                _payVotersOfWinningStatement(1);
                _affirmationBlockedBySdc();
            } 
            //in any case, discussion ended
            _closeCds();


        } else { //There is more than one objection
        //Compare last objection with penultimate objection
            if(statementVoteCount[length-2] > statementVoteCount[length-1]){
                _payVotersOfWinningStatement(length-2); //voters of winning statement get the prize

                //penultimate statement wins. It cancels the last statement from the debate
                statements.pop(); //remove last statement
                //THERE ARE VOTERS POINTING TO THAT ERASED STATEMENT ON voterToStatement. THIS IS POTENTIALLY A MEMORY BREACH
                length = length - 1; //reduce array length

            } else if(statementVoteCount[length-2] <= statementVoteCount[length-1]) {
                _payVotersOfWinningStatement(length-1); //voters of winning statement get the prize

                //last statement wins. It cancels previous objection and make the debate go back to statement on position (length - 3)
                statements.pop();
                statements.pop();
                //THERE ARE VOTERS POINTING TO THAT ERASED STATEMENT ON voterToStatement. THIS IS POTENTIALLY A MEMORY BREACH
                length = length - 2;
            }
                statements[length-1].open = true; //sets the new last statement's open flag to true
        }
    }

    function getStatement(uint id) public view{
        require((_idExists(id)), "Invalid id provided");

    }

}
