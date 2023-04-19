// SPDX-License-Identifier: GPL-3.0
// Version of compiler
pragma solidity >=0.7.0 <0.9.0;

//sdc v2: only affirmation and one objection

//contract == new affirmation
contract sdc {

    struct objection {
        address payable o_owner;    // who stated this objection
        uint closedAt;              // when should it be closed
        string o_string;            // objection statement
        address[] votes;            // who has voted for this one
        bool exist;                 // is currently receiving votes?
        bool winner;                // is winner?
    }

    struct affirmation {
        string a_string;            // who stated this affirmation
        address[] votes;            // who has voted for this one
        bool active;                // is active?
        objection objection;        // 1 objection by now
        uint current_objections;    // number of current objections
    }

    address payable public owner;   // who stated this affirmation
    uint public createdAt;          // when it was created
    uint public closedAt;           // when it should close
    affirmation new_a;              //contract main affirmation
    address[] voters;               // who has voted in this contract (affirmation + objections)
    uint public contract_value;     // how much money this contract is holding
    bool public payed_dividends;    // has this contract payed its dividends?

    //addresses (users) will have both data
    mapping(address => bool) already_voted;     // logs which users have voted
    mapping(address => uint) statement_voted;   // logs in which statement they've voted to
    mapping(address => uint) money_owned;       // logs how much money is owned to each person

    event print_money( 
        address indexed _from, 
        uint256 _value 
    );

    constructor(string memory _str) payable {
        owner = payable(msg.sender);
        require(msg.value == 5000000000000000000, "To create an affirmation, you should pay 5 ether"); // owner needs the money to create affirmation
        createdAt = block.timestamp;
        new_a.active = true; //active during timestamp
        new_a.a_string = _str;
        new_a.current_objections = 0; //0 current objections
        contract_value = 5000000000000000000;
        //closedAt = createdAt + 2 days;
        closedAt = createdAt + 2 minutes; //just for testing
    }

    modifier is_owner() {
        require(msg.sender == owner, "do not own affirmation contract");
        _;
    }

    modifier not_owner() {
        require(msg.sender != owner, "own main affirmation");
        _;
    }

    modifier objection_exist(uint _num) { // needed for more objections
        require((new_a.objection.exist == true || new_a.active == true), "objection does not exist");
        _;
    }

    modifier can_vote(uint _num) {
        require((statement_voted[msg.sender] < _num)||(already_voted[msg.sender]==false), "cannot vote for previus statement");
        _;
    }

    modifier active {
        require(new_a.active == true, "affirmation time is done");
        _;
    }

    function get_money_owned(address _adr) external {
        emit print_money(_adr, money_owned[_adr]);
    }

    function get_statement(uint _num) external view
    objection_exist(_num) returns(string memory) {
        if(_num == 0){
            return new_a.a_string; //returns main affirmation
        }
        else{
            return new_a.objection.o_string; //returns objection
        }
    }

    function vote(uint _num) public payable
    objection_exist(_num) can_vote(_num) active() {
        require(msg.value == 1000000000000000000 || already_voted[msg.sender] == true, "To vote you should pay 1 ether"); // owner needs the money to vote
        require(block.timestamp < closedAt, "affirmation expired"); // affirmation should be active

        if(already_voted[msg.sender] == false) {
            contract_value += 1000000000000000000;
            already_voted[msg.sender] = true;
        }
        else {
            // already voted for affirmation and is changing to objection
            for(uint i = 0; i < new_a.votes.length; i++) {
                if(new_a.votes[i] == msg.sender) {
                    new_a.votes[i] = new_a.votes[new_a.votes.length - 1];
                    new_a.votes.pop();
                }
            }
        }
        if(_num == 0){
            new_a.votes.push(msg.sender);
        }
        else{
            new_a.objection.votes.push(msg.sender);
        }
        statement_voted[msg.sender] = _num;
        voters.push(msg.sender);
    }

    function get_votes(uint _num) external view
    objection_exist(_num) returns(uint) {
        if(_num == 0){
            return new_a.votes.length; // returns affirmation's number of votes
        }
        else{
            return new_a.objection.votes.length; // returns objection's number of votes
        }
    }

    function current_objections() external view returns(uint) {
        return new_a.current_objections; // returns number of current objections
    }

    function create_objection(string memory _s) external payable
    not_owner() active() {
        require(msg.value == 5000000000000000000, "To create an objection, you should pay 5 ether"); // owner needs the money to create objection
        require(new_a.objection.exist == false, "Objection already exists"); // for one objection only
        new_a.current_objections += 1;
        new_a.objection.o_owner = payable(msg.sender);
        new_a.objection.o_string = _s;
        new_a.objection.exist = true;
        contract_value += 5000000000000000000;
    }

    function evaluate_winners() private active() {
        // see who won the objection(s) and/or affirmation and update money_owned
        payed_dividends = true;
        uint total_owned = 0;
        if(new_a.objection.votes.length > new_a.votes.length){ // objection has more votes
            // updates money_owned 
            for(uint i = 0; i < new_a.objection.votes.length; i++) {
                money_owned[new_a.objection.votes[i]] += 1000000000000000000;
                total_owned += 1000000000000000000;
            }
            money_owned[new_a.objection.o_owner] += 5000000000000000000;
            total_owned += 5000000000000000000;
        }
        else { //affirmation has more votes
            // updates money_owned 
            for(uint i = 0; i < new_a.votes.length; i++) {
                money_owned[new_a.votes[i]] += 1000000000000000000;
                total_owned += 1000000000000000000;
            }
            money_owned[owner] += 5000000000000000000;
            total_owned += 5000000000000000000;
        }
        uint dividends;
        dividends = contract_value - total_owned;
        total_owned = 0;
        if(new_a.objection.votes.length > new_a.votes.length){ // objection has more votes
            // updates money_owned
            money_owned[new_a.objection.o_owner] += dividends/2; // statement owner receives half earnings
            dividends -= (dividends/2);
            for(uint i = 0; i < new_a.objection.votes.length; i++) {
                money_owned[new_a.objection.votes[i]] += (dividends / new_a.objection.votes.length);
                total_owned += (dividends / new_a.objection.votes.length);
            }
            dividends -= total_owned;
            money_owned[new_a.objection.o_owner] += dividends; // statement owner receives leftovers
        }
        else { //affirmation has more votes
            // updates money_owned
            money_owned[owner] += dividends/2; // statement owner receives half earnings
            dividends -= (dividends/2);
            for(uint i = 0; i < new_a.votes.length; i++) {
                money_owned[new_a.votes[i]] += (dividends / new_a.votes.length);
                total_owned += (dividends / new_a.votes.length);
            }
            dividends -= total_owned;
            money_owned[owner] += dividends; // statement owner receives leftovers
        }
        contract_value = 0;
        new_a.active = false;
    }

    function should_pay() public active() {
        // test if it's time to pay dividends
        if(block.timestamp > closedAt && payed_dividends == false) 
            evaluate_winners();
    }

    function withdraw() external {
        // users can withdraw amount won
        uint amount = money_owned[msg.sender];
        if (amount > 0) {
            
            money_owned[msg.sender] = 0;

            payable(msg.sender).transfer(amount);
        }
    }
}
