"""
outputs Halstead metrics and cyclomatic complexity for a given java file
"""

import argparse
import os.path
import sys


from javalang import tokenizer

from halstead_cyclomatic.cyclomatic import calculate_cyclomatic
from halstead_cyclomatic.get_operators_operands_count import \
    get_operators_operands_count
from halstead_cyclomatic.halstead import calculate_halstead


def pretty_print(data):
    """print dictionary items separated by a ':' and the number of tabs required to align the values

    Args:
        data (dictionary): dictionary to print
    """
    longest_key_len = len(max(data.keys(), key=len))
    tabs = '\t' * (longest_key_len // 4)

    for key, value in data.items():
        print(f"\t{key}:{tabs}{round(value, 2)}")


def print_separator():
    """prints a line of '-' surrounded by '\n'
    """
    print(f"\n{'-' * 150}\n")


parser = argparse.ArgumentParser(
    description='outputs Halstead metrics and cyclomatic complexity for a given java file')
parser.add_argument('java_file', metavar='JAVA_FILE', type=str,
                    help='path to the java file')

args = parser.parse_args()

if not os.path.isfile(args.java_file):
    print('Invalid Java File')
    sys.exit()

with open(args.java_file, 'r', encoding='utf-8') as file:
    code = file.read()
    tokens = list(tokenizer.tokenize(code))

    operators, operands = get_operators_operands_count(tokens)

    print("Operators:")
    pretty_print(operators)

    print("Operands:")
    pretty_print(operands)

    print_separator()

    n1 = len(operators)
    n2 = len(operands)
    N1 = sum(operators.values())
    N2 = sum(operands.values())

    print(f"n1:\t{n1}")
    print(f"n2:\t{n2}")
    print(f"N1:\t{N1}")
    print(f"N2:\t{N2}")

    print_separator()

    halstead = calculate_halstead(n1, N1, n2, N2)
    print("Halstead Complexity: \n")
    pretty_print(halstead)

    print_separator()
    print(f"Cyclomatic complexity: {calculate_cyclomatic(operators)}")
