// SPDX-License-Identifier: GPL-3.0
// Version of compiler
pragma solidity >=0.7.0 <0.9.0;

//cds v2: only affirmation and one objection

//contract == new affirmation
contract cds {

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

    struct operator {                           // used for the source code complexity analysis
        string op;
        bool is_unique;
    }

    event print_money( 
        address indexed _from, 
        uint256 _value 
    );

    constructor(string memory _str, string[][] memory _str_tokens) payable {
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


    //functions for source code complexity analysis

    function complexity_analysis(string memory _str, string[][] memory _str_tokens) private pure returns (int){
        
        //build string from array of source code tokens provided
        string memory _str_built_from_tokens = build_parsed_str(_str_tokens);

        if(compare_str(_str, _str_built_from_tokens)){
            //if the source code given in _str is equal to the string built from _str_tokens, it starts the complexity analysis
            uint256 N1 = 0; //total of operators
            uint256 N2 = 0; //total of operands
            uint256 n1 = 0; //number of unique operators
            uint256 n2 = 0; //number of unique operands

            //map the list of valid operators
            operator[] memory valid_operators = new operator[](58);
            valid_operators[0].op = "+";
            valid_operators[0].is_unique = true;

            valid_operators[1].op = "-";
            valid_operators[1].is_unique = true;

            valid_operators[2].op = "*";
            valid_operators[2].is_unique = true;

            valid_operators[3].op = "/";
            valid_operators[3].is_unique = true;

            valid_operators[4].op = "%";
            valid_operators[4].is_unique = true;

            valid_operators[5].op = "**";
            valid_operators[5].is_unique = true;

            valid_operators[6].op = "//";
            valid_operators[6].is_unique = true;

            valid_operators[7].op = "False";
            valid_operators[7].is_unique = true;

            valid_operators[8].op = "None";
            valid_operators[8].is_unique = true;

            valid_operators[9].op = "True";
            valid_operators[9].is_unique = true;

            valid_operators[10].op = "and";
            valid_operators[10].is_unique = true;

            valid_operators[11].op = "as";
            valid_operators[11].is_unique = true;

            valid_operators[12].op = "assert";
            valid_operators[12].is_unique = true;

            valid_operators[13].op = "async";
            valid_operators[13].is_unique = true;

            valid_operators[14].op = "await";
            valid_operators[14].is_unique = true;

            valid_operators[15].op = "break";
            valid_operators[15].is_unique = true;

            valid_operators[16].op = "class";
            valid_operators[16].is_unique = true;

            valid_operators[17].op = "continue";
            valid_operators[17].is_unique = true;

            valid_operators[18].op = "def";
            valid_operators[18].is_unique = true;

            valid_operators[19].op = "del";
            valid_operators[19].is_unique = true;

            valid_operators[20].op = "elif";
            valid_operators[20].is_unique = true;

            valid_operators[21].op = "else";
            valid_operators[21].is_unique = true;

            valid_operators[22].op = "except";
            valid_operators[22].is_unique = true;

            valid_operators[23].op = "finally";
            valid_operators[23].is_unique = true;

            valid_operators[24].op = "for";
            valid_operators[24].is_unique = true;

            valid_operators[25].op = "from";
            valid_operators[25].is_unique = true;

            valid_operators[26].op = "global";
            valid_operators[26].is_unique = true;

            valid_operators[27].op = "if";
            valid_operators[27].is_unique = true;

            valid_operators[28].op = "import";
            valid_operators[28].is_unique = true;

            valid_operators[29].op = "in";
            valid_operators[29].is_unique = true;

            valid_operators[30].op = "is";
            valid_operators[30].is_unique = true;

            valid_operators[31].op = "nonlocal";
            valid_operators[31].is_unique = true;

            valid_operators[32].op = "not";
            valid_operators[32].is_unique = true;

            valid_operators[33].op = "or";
            valid_operators[33].is_unique = true;

            valid_operators[34].op = "pass";
            valid_operators[34].is_unique = true;

            valid_operators[35].op = "raise";
            valid_operators[35].is_unique = true;

            valid_operators[36].op = "return";
            valid_operators[36].is_unique = true;

            valid_operators[37].op = "try";
            valid_operators[37].is_unique = true;

            valid_operators[38].op = "while";
            valid_operators[38].is_unique = true;

            valid_operators[39].op = "with";
            valid_operators[39].is_unique = true;

            valid_operators[40].op = "yield";
            valid_operators[40].is_unique = true;

            valid_operators[41].op = "with";
            valid_operators[41].is_unique = true;

            valid_operators[42].op = "<";
            valid_operators[42].is_unique = true;

            valid_operators[43].op = ">";
            valid_operators[43].is_unique = true;

            valid_operators[44].op = "<=";
            valid_operators[44].is_unique = true;

            valid_operators[45].op = ">=";
            valid_operators[45].is_unique = true;

            valid_operators[46].op = "==";
            valid_operators[46].is_unique = true;

            valid_operators[47].op = "!=";
            valid_operators[47].is_unique = true;

            valid_operators[48].op = "(";
            valid_operators[48].is_unique = true;

            valid_operators[49].op = ")";
            valid_operators[49].is_unique = true;

            valid_operators[50].op = "[";
            valid_operators[50].is_unique = true;

            valid_operators[51].op = "]";
            valid_operators[51].is_unique = true;

            valid_operators[52].op = "{";
            valid_operators[52].is_unique = true;

            valid_operators[53].op = "}";
            valid_operators[53].is_unique = true;

            valid_operators[54].op = "->";
            valid_operators[54].is_unique = true;

            valid_operators[55].op = "@";
            valid_operators[55].is_unique = true;

            valid_operators[56].op = ";";
            valid_operators[56].is_unique = true;

            valid_operators[57].op = ",";
            valid_operators[57].is_unique = true;


            //iterate throught list of tokens and fill 
            for(uint256 i = 0; keccak256(abi.encodePacked(_str_tokens[i][1])) != keccak256(abi.encodePacked("EOF")); i++) {
                for(uint j = 0; j < valid_operators.length; j++) {
                    if(keccak256(abi.encodePacked(_str_tokens[i][0])) != keccak256(abi.encodePacked(valid_operators[j].op))) {
                        if(valid_operators[j].is_unique == true) {
                            valid_operators[j].is_unique = false;
                            n1++;
                        }
                        N1++;
                    } else {
                        N2++;
                    }
                }
            }
            


        
        } else {
            //if _str_built_from_tokens is not equal to _str, the source codes do not match, and the contract won't build!
            return -1;
        }
    }

    //helper of complexity_analysis()
    function build_parsed_str(string[][] memory _str_tokens) private pure returns (string memory) {
        string memory _new_str = "";

        for(uint256 i = 0; keccak256(abi.encodePacked(_str_tokens[i][1])) != keccak256(abi.encodePacked("EOF")); i++) {
            string memory token = _str_tokens[i][0];

            /*each _str_tokens[i][1] has a code that can be "s", "n", "t", "c":
            s -> space
            n -> new line
            t -> whitespace
            c -> concatenate
            EOF -> end of file

            These help this string builder function to build back the source code from the tokens for it to be exactly equal to the original source code
            */
            if(keccak256(abi.encodePacked(_str_tokens[i][1])) == keccak256(abi.encodePacked("s"))) {
                _new_str = string.concat(_new_str, string.concat(token, " "));
            } else if(keccak256(abi.encodePacked(_str_tokens[i][1])) == keccak256(abi.encodePacked("n"))) {
                _new_str = string.concat(_new_str, string.concat(token, "\n"));               
            } else if(keccak256(abi.encodePacked(_str_tokens[i][1])) == keccak256(abi.encodePacked("t"))) {
                _new_str = string.concat(_new_str, string.concat(token, "\t"));               
            } else if(keccak256(abi.encodePacked(_str_tokens[i][1])) == keccak256(abi.encodePacked("c"))) {
                _new_str = string.concat(_new_str, token);               
            } else if(keccak256(abi.encodePacked(_str_tokens[i][1])) == keccak256(abi.encodePacked("EOF"))) {
                _new_str = string.concat(_new_str, token);                
            }
        }

        return _new_str;
    }

    //helper of complexity_analysis()
    function compare_str(string memory _str, string memory _str_built_from_tokens) private pure returns (bool) {
        //will compare the hash of each of the strings
        if(keccak256(abi.encodePacked(_str)) == keccak256(abi.encodePacked(_str_built_from_tokens))) {
            return true;
        } else {
            return false;
        }
    }

}
