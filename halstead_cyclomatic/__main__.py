"""
outputs Halstead metrics and cyclomatic complexity for a given java file
"""

import ipfshttpclient
import argparse
import os.path
import sys
from web3 import Web3


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
    print(f"Error retrieving file with CID {cid} from IPFS: {e}")



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


#Now, needs to send these values to the blockchain for the CDS contract

