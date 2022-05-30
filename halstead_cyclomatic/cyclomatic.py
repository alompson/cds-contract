"""
calculate cyclomatic complexity
"""

import json

with open('branchOperators.json', 'r', encoding='utf-8') as branchOperatorsJson:
    branchOperators = set(json.load(branchOperatorsJson))


def calculate_cyclomatic(operators):
    """_summary_

    Args:
        operators (dictionary operator:count): dictionary of operators and their count

    Returns:
        int: cyclomatic complexity
    """
    return sum([operators[cyc_operator]
                for cyc_operator in branchOperators if cyc_operator in operators], start=1)
