import math
import re

def count_joins(sql_content):
    """Count number of JOIN operations"""
    join_pattern = r'\b(JOIN|INNER JOIN|LEFT JOIN|RIGHT JOIN|FULL JOIN|OUTER JOIN)\b'
    return len(re.findall(join_pattern, sql_content.upper()))

def count_unique_tables(sql_content):
    """Count unique table references"""
    # Match table names in FROM and JOIN clauses
    from_pattern = r'\bFROM\s+([a-zA-Z_][a-zA-Z0-9_]*)'
    join_pattern = r'\bJOIN\s+([a-zA-Z_][a-zA-Z0-9_]*)'
    
    tables = set()
    tables.update(re.findall(from_pattern, sql_content.upper()))
    tables.update(re.findall(join_pattern, sql_content.upper()))
    return len(tables)

def count_virtual_tables(sql_content):
    """Count virtual tables (CTEs and derived tables)"""
    cte_pattern = r'\bWITH\s+[a-zA-Z_][a-zA-Z0-9_]*\s+AS\s*\('
    derived_pattern = r'\)\s+AS\s+[a-zA-Z_][a-zA-Z0-9_]*'
    
    ctes = len(re.findall(cte_pattern, sql_content.upper()))
    derived = len(re.findall(derived_pattern, sql_content.upper()))
    return ctes + derived

def count_updates_deletes(sql_content):
    """Count UPDATE and DELETE statements"""
    update_pattern = r'\bUPDATE\b'
    delete_pattern = r'\bDELETE\b'
    
    updates = len(re.findall(update_pattern, sql_content.upper()))
    deletes = len(re.findall(delete_pattern, sql_content.upper()))
    return updates + deletes


def calculate_complexity_score(metrics):
#calculate the simple weight sum of script attributes

    weights = {
        'line_of_code': 0.3,
        'join_density': 0.3,
        'unique_table_density': 0.1,
        'virtual_table_density': 0.1,
        'update_delete_density': 0.2
    }

    # Use exponential scaling, capping at 100
    score = (
        weights['line_of_code'] * metrics['loc'] +
        weights['join_density'] * metrics['joins'] +
        weights['unique_table_density'] * metrics['unique_tables']  +
        weights['virtual_table_density'] * metrics['virtual_tables'] +
        weights['update_delete_density'] * metrics['updates_deletes'] 
    )

    return score


def analyze_sql_complexity(file_path):
    """
    Analyzes a Teradata SQL file and returns a complexity score between 1 and 100.
    The score is based on various complexity factors like LOC, joins, table count, etc.
    """
    try:
        with open(file_path, 'r') as file:
            sql_content = file.read()
    except FileNotFoundError:
        return f"Error: File {file_path} not found."
    except Exception as e:
        return f"Error reading file: {str(e)}"

    # Remove comments and empty lines
    sql_content = re.sub(r'--.*$', '', sql_content, flags=re.MULTILINE)
    sql_content = re.sub(r'/\*.*?\*/', '', sql_content, flags=re.DOTALL)
    lines = [line.strip() for line in sql_content.split('\n') if line.strip()]
    
    # Calculate metrics
    metrics = {
        'loc': len(lines),
        'joins': count_joins(sql_content),
        'unique_tables': count_unique_tables(sql_content),
        'virtual_tables': count_virtual_tables(sql_content),
        'updates_deletes': count_updates_deletes(sql_content)
    }
    
    # Calculate complexity score
    score = calculate_complexity_score(metrics)
    
    return {
        'complexity_score': score,
        'metrics': metrics
    }

# Replace this with your SQL file path
file_path = "test_hard.sql"
result = analyze_sql_complexity(file_path)

if isinstance(result, str):  # Error message
    print(result)
else:
    print("\nSQL Complexity Analysis")
    print("----------------------")
    print(f"Complexity Score: {result['complexity_score']}")
    print("\nDetailed Metrics:")
    for metric, value in result['metrics'].items():
        print(f"- {metric.replace('_', ' ').title()}: {value}")
