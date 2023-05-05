"""
outputs Halstead metrics and cyclomatic complexity for a given java file
"""

import ipfshttpclient
import argparse
import os.path
import sys
import web3
import w3
from web3 import Web3, Account


from javalang import tokenizer
from tabulate import tabulate

from halstead_cyclomatic.cyclomatic import calculate_cyclomatic
from halstead_cyclomatic.get_operators_operands_count import \
    get_operators_operands_count
from halstead_cyclomatic.halstead import calculate_halstead


def print_table(data, headers=[], title=None):
    """print dictionary as a two column table

    Args:
        data (dictionary): dictionary to print
        headers (list): table headers
        title (str): table title
    """
    if title:
        print("\n", title, "\n")
    print(tabulate(data.items(), headers=headers, tablefmt='fancy_grid'))


"""
parser = argparse.ArgumentParser(
    description='outputs Halstead metrics and cyclomatic complexity for a given java file')

#parser = file_contents
parser.add_argument('java_file', metavar='JAVA_FILE', type=str,
                    help='path to the java file')

args = parser.parse_args()

if not os.path.isfile(args.java_file):
    print('Invalid Java File')
    sys.exit()

with open(args.java_file, 'r', encoding='utf-8') as file:
    code = file.read()
"""

#NEW VERSION: READING FROM IPFS INSTEAD OF FILE PATH
try:

    #cid is given as an argument
    #         
    parser = argparse.ArgumentParser(description='outputs Halstead metrics and cyclomatic complexity for a given java file')
    parser.add_argument('cid', metavar='CID', type=str, help='CID of the Java file in IPFS')
    
    args = parser.parse_args()


    client = ipfshttpclient.connect('/ip4/127.0.0.1/tcp/5001')
    # retrieve file from IPFS using its CID
    # Retrieve the file contents as bytes
    file_contents = client.cat(args.cid)

    #print("\n\nSOURCE CODE:\n\n")
    #print(file_contents)
    
except Exception as e:
    print(f"Error retrieving file with CID {args} from IPFS: {e}")



code = file_contents.decode('utf-8')


tokens = list(tokenizer.tokenize(code))

operators, operands = get_operators_operands_count(tokens)

n1 = len(operators)
n2 = len(operands)
N1 = sum(operators.values())
N2 = sum(operands.values())

cyclomatic = calculate_cyclomatic(operators)
halstead_dif = int(calculate_halstead(n1, N1, n2, N2))

print_table(
    {'Cyclomatic complexity': cyclomatic})


#Does not need all the values, only difficulty
print_table({'Halstead Difficulty': halstead_dif})


# Now, needs to send these values to the blockchain for the CDS contract
# In this implementation, the contract will be deployed manually on Remix IDE using a Ganache local blockchain

# Using a source code with:
## Cyclomatic complexity = 4
## Halstead difficulty = 59


# # using a local Ganache Server, combined with Remix IDE for smart contract deployment
# w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:7545'))

# # after deploying contract manually, this is the resulting abi
# abi = [
# 	{
# 		"inputs": [
# 			{
# 				"internalType": "uint256",
# 				"name": "previousVoteId",
# 				"type": "uint256"
# 			}
# 		],
# 		"name": "changeVote",
# 		"outputs": [],
# 		"stateMutability": "payable",
# 		"type": "function"
# 	},
# 	{
# 		"inputs": [
# 			{
# 				"internalType": "string",
# 				"name": "objection",
# 				"type": "string"
# 			}
# 		],
# 		"name": "createObjection",
# 		"outputs": [],
# 		"stateMutability": "payable",
# 		"type": "function"
# 	},
# 	{
# 		"inputs": [
# 			{
# 				"internalType": "string",
# 				"name": "cid",
# 				"type": "string"
# 			},
# 			{
# 				"internalType": "uint256",
# 				"name": "halstead",
# 				"type": "uint256"
# 			},
# 			{
# 				"internalType": "uint256",
# 				"name": "cyclomatic",
# 				"type": "uint256"
# 			}
# 		],
# 		"stateMutability": "payable",
# 		"type": "constructor"
# 	},
# 	{
# 		"anonymous": "false",
# 		"inputs": [
# 			{
# 				"indexed": "false",
# 				"internalType": "string",
# 				"name": "content",
# 				"type": "string"
# 			},
# 			{
# 				"indexed": "false",
# 				"internalType": "uint256",
# 				"name": "createdAt",
# 				"type": "uint256"
# 			},
# 			{
# 				"indexed": "false",
# 				"internalType": "uint256",
# 				"name": "closesAt",
# 				"type": "uint256"
# 			}
# 		],
# 		"name": "newStatement",
# 		"type": "event"
# 	},
# 	{
# 		"inputs": [],
# 		"name": "settleDebate",
# 		"outputs": [],
# 		"stateMutability": "nonpayable",
# 		"type": "function"
# 	},
# 	{
# 		"inputs": [
# 			{
# 				"internalType": "uint256",
# 				"name": "id",
# 				"type": "uint256"
# 			}
# 		],
# 		"name": "vote",
# 		"outputs": [],
# 		"stateMutability": "payable",
# 		"type": "function"
# 	},
# 	{
# 		"inputs": [
# 			{
# 				"internalType": "uint256",
# 				"name": "id",
# 				"type": "uint256"
# 			}
# 		],
# 		"name": "getStatement",
# 		"outputs": [],
# 		"stateMutability": "view",
# 		"type": "function"
# 	},
# 	{
# 		"inputs": [
# 			{
# 				"internalType": "address",
# 				"name": "",
# 				"type": "address"
# 			}
# 		],
# 		"name": "hasVoted",
# 		"outputs": [
# 			{
# 				"internalType": "bool",
# 				"name": "",
# 				"type": "bool"
# 			}
# 		],
# 		"stateMutability": "view",
# 		"type": "function"
# 	},
# 	{
# 		"inputs": [
# 			{
# 				"internalType": "uint256",
# 				"name": "",
# 				"type": "uint256"
# 			}
# 		],
# 		"name": "statementToOwner",
# 		"outputs": [
# 			{
# 				"internalType": "address",
# 				"name": "",
# 				"type": "address"
# 			}
# 		],
# 		"stateMutability": "view",
# 		"type": "function"
# 	},
# 	{
# 		"inputs": [
# 			{
# 				"internalType": "uint256",
# 				"name": "",
# 				"type": "uint256"
# 			}
# 		],
# 		"name": "statementVoteCount",
# 		"outputs": [
# 			{
# 				"internalType": "uint256",
# 				"name": "",
# 				"type": "uint256"
# 			}
# 		],
# 		"stateMutability": "view",
# 		"type": "function"
# 	},
# 	{
# 		"inputs": [
# 			{
# 				"internalType": "address",
# 				"name": "",
# 				"type": "address"
# 			}
# 		],
# 		"name": "voterToStatement",
# 		"outputs": [
# 			{
# 				"internalType": "string",
# 				"name": "content",
# 				"type": "string"
# 			},
# 			{
# 				"internalType": "bool",
# 				"name": "open",
# 				"type": "bool"
# 			},
# 			{
# 				"internalType": "uint256",
# 				"name": "createdAt",
# 				"type": "uint256"
# 			},
# 			{
# 				"internalType": "uint256",
# 				"name": "closesAt",
# 				"type": "uint256"
# 			}
# 		],
# 		"stateMutability": "view",
# 		"type": "function"
# 	}
# ]

# contract_address = '0x5Cf3c64e6C6Fe46Db3225220118EC2BD8f3B062C'

# contract = w3.eth.contract(address=contract_address, abi=abi)

# #contract is a Python object that represenst the smart contract

# #test the creation of an objection:

# sender_address = '0x20ced187fB9FbAD0711580d9001BE99A01B33c11'
# nonce = 1

# function_signature = contract.functions.createObjection("your code sucks").build_transaction({'gas': 1000000})['data']

# transaction = {
#     'to': contract_address,
#     'from': sender_address,
#     'value': Web3.to_wei(5, 'ether'),
#     'gas': 6721975,
#     'gasPrice': Web3.to_wei(20, 'gwei'),
#     'nonce': nonce,
#     'data': function_signature,
# }

# private_key = '0x1d2696551f3ef144407e6cb1e68936585121a4e467a35c704284c8b8bca0fa97'
# signed_txn = Account.sign_transaction(transaction, private_key)
# tx_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)


