# Python Cheat Sheet (Beginner → Expert)

> Covers Python basics, data types, control flow, functions, OOP, modules, file I/O, exceptions, libraries, testing, best practices, advanced features, and common pitfalls.

---

## Table of Contents

1. [Introduction & Setup](#1-introduction--setup)
2. [Data Types & Variables](#2-data-types--variables)
3. [Operators & Expressions](#3-operators--expressions)
4. [Control Flow](#4-control-flow)
5. [Functions](#5-functions)
6. [Classes & OOP](#6-classes--oop)
7. [Modules & Packages](#7-modules--packages)
8. [File I/O](#8-file-io)
9. [Exceptions & Error Handling](#9-exceptions--error-handling)
10. [Popular Libraries](#10-popular-libraries)
11. [Testing & Debugging](#11-testing--debugging)
12. [Virtual Environments & Package Management](#12-virtual-environments--package-management)
13. [Best Practices & Tips](#13-best-practices--tips)
14. [Advanced Python Features](#14-advanced-python-features)
15. [Common Pitfalls and Gotchas](#15-common-pitfalls-and-gotchas)

---

# 1. Introduction & Setup

* Install Python: [https://www.python.org/downloads/](https://www.python.org/downloads/)
* Check version:

```bash
python3 --version
```

* Run script:

```bash
python3 script.py
```

---

# 2. Data Types & Variables

* Basic types: `int`, `float`, `str`, `bool`
* Collections: `list`, `tuple`, `set`, `dict`
* Type checking & type hints:

```python
from typing import List, Dict, Optional

# Type hints (Python 3.5+)
name: str = "Alice"
age: int = 25
scores: List[float] = [85.5, 92.0, 78.5]
user_data: Dict[str, str] = {"name": "Bob", "email": "bob@example.com"}

def greet(name: str) -> str:
    return f"Hello, {name}!"  # f-strings (Python 3.6+)

# Walrus operator (Python 3.8+)
if (n := len(scores)) > 0:
    average = sum(scores) / n
    print(f"Average: {average:.2f}")

# Optional types
def find_user(user_id: int) -> Optional[Dict[str, str]]:
    # Implementation here
    pass
```

---

# 3. Operators & Expressions

* Arithmetic: `+ - * / // % **`
* Comparison: `== != > < >= <=`
* Logical: `and or not`
* Membership: `in, not in`
* Identity: `is, is not`

---

# 4. Control Flow

* If/Else:

```python
if x > 0:
    print("Positive")
elif x == 0:
    print("Zero")
else:
    print("Negative")
```

* Match/Case (Python 3.10+):

```python
def handle_command(command):
    match command:
        case "start":
            return "Starting..."
        case "stop":
            return "Stopping..."
        case "restart":
            return "Restarting..."
        case _:
            return "Unknown command"
```

* Loops:

```python
# For loop with enumerate
for i, value in enumerate(['a', 'b', 'c']):
    print(f"{i}: {value}")

# While with else
x = 0
while x < 3:
    print(x)
    x += 1
else:
    print("Loop completed")

# Break and continue
for num in range(10):
    if num == 5:
        break  # Exit loop
    if num % 2 == 0:
        continue  # Skip even numbers
    print(num)
```

* Comprehensions:

```python
# List comprehension
squares = [x**2 for x in range(10) if x % 2 == 0]

# Dict comprehension
squares_dict = {x: x**2 for x in range(5)}

# Set comprehension
even_squares = {x**2 for x in range(10) if x % 2 == 0}

# Nested comprehensions
matrix = [[i*j for j in range(3)] for i in range(3)]
```

---

# 5. Functions

* Define function with type hints:

```python
from typing import Union, Callable

def add(a: int, b: int) -> int:
    """Add two numbers together."""
    return a + b

def calculate_area(length: float, width: float) -> float:
    return length * width
```

* Args and kwargs:

```python
def flexible_function(*args: int, **kwargs: str) -> None:
    """Accepts any number of positional and keyword arguments."""
    print(f"Args: {args}")
    print(f"Kwargs: {kwargs}")

# Usage
flexible_function(1, 2, 3, name="Alice", age="25")
```

* Lambda functions:

```python
# Simple lambda
square = lambda x: x ** 2
print(square(5))  # 25

# Lambda with multiple arguments
add = lambda x, y: x + y

# Lambda in sorting
points = [(1, 2), (3, 1), (5, 0)]
points.sort(key=lambda p: p[1])  # Sort by y-coordinate
```

* Decorators:

```python
def timer(func: Callable) -> Callable:
    """Decorator that times function execution."""
    def wrapper(*args, **kwargs):
        import time
        start = time.time()
        result = func(*args, **kwargs)
        end = time.time()
        print(f"{func.__name__} took {end - start:.2f} seconds")
        return result
    return wrapper

@timer
def slow_function():
    import time
    time.sleep(1)
    return "Done"

# Class-based decorator
class CountCalls:
    def __init__(self, func):
        self.func = func
        self.count = 0

    def __call__(self, *args, **kwargs):
        self.count += 1
        print(f"Call {self.count} to {self.func.__name__}")
        return self.func(*args, **kwargs)
```

* Closures and nested functions:

```python
def outer_function(x):
    def inner_function(y):
        return x + y
    return inner_function

add_five = outer_function(5)
print(add_five(3))  # 8
```

---

# 6. Classes & OOP

* Define class with type hints and dataclasses:

```python
from dataclasses import dataclass
from typing import ClassVar

@dataclass
class Person:
    name: str
    age: int
    species: ClassVar[str] = "Human"  # Class variable

    def greet(self) -> str:
        return f"Hello, I'm {self.name}, {self.age} years old"

# Usage
person = Person("Alice", 30)
print(person.greet())  # Hello, I'm Alice, 30 years old
```

* Properties and encapsulation:

```python
class BankAccount:
    def __init__(self, balance: float):
        self._balance = balance  # Protected attribute

    @property
    def balance(self) -> float:
        return self._balance

    @balance.setter
    def balance(self, value: float) -> None:
        if value < 0:
            raise ValueError("Balance cannot be negative")
        self._balance = value

    def deposit(self, amount: float) -> None:
        self.balance += amount

    def withdraw(self, amount: float) -> None:
        if amount > self.balance:
            raise ValueError("Insufficient funds")
        self.balance -= amount
```

* Inheritance and polymorphism:

```python
from abc import ABC, abstractmethod

class Shape(ABC):
    @abstractmethod
    def area(self) -> float:
        pass

    @abstractmethod
    def perimeter(self) -> float:
        pass

class Rectangle(Shape):
    def __init__(self, width: float, height: float):
        self.width = width
        self.height = height

    def area(self) -> float:
        return self.width * self.height

    def perimeter(self) -> float:
        return 2 * (self.width + self.height)

class Circle(Shape):
    def __init__(self, radius: float):
        self.radius = radius

    def area(self) -> float:
        return 3.14159 * self.radius ** 2

    def perimeter(self) -> float:
        return 2 * 3.14159 * self.radius

# Polymorphism in action
shapes = [Rectangle(4, 5), Circle(3)]
for shape in shapes:
    print(f"Area: {shape.area():.2f}, Perimeter: {shape.perimeter():.2f}")
```

* Magic methods (dunder methods):

```python
class Vector:
    def __init__(self, x: float, y: float):
        self.x = x
        self.y = y

    def __add__(self, other: 'Vector') -> 'Vector':
        return Vector(self.x + other.x, self.y + other.y)

    def __str__(self) -> str:
        return f"Vector({self.x}, {self.y})"

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Vector):
            return NotImplemented
        return self.x == other.x and self.y == other.y

# Usage
v1 = Vector(1, 2)
v2 = Vector(3, 4)
print(v1 + v2)  # Vector(4, 6)
print(v1 == Vector(1, 2))  # True
```

---

# 7. Modules & Packages

* Import module:

```python
import math
from math import sqrt
```

* Create package:

```
mypackage/
  __init__.py
  module1.py
```

* Install external packages:

```bash
pip install requests
```

---

# 8. File I/O

* Read file:

```python
with open('file.txt', 'r') as f:
    data = f.read()
```

* Write file:

```python
with open('file.txt', 'w') as f:
    f.write('Hello')
```

* JSON:

```python
import json
data = json.loads(json_str)
json_str = json.dumps(data)
```

---

# 9. Exceptions & Error Handling

* Try/Except:

```python
try:
    x = 10/0
except ZeroDivisionError:
    print("Cannot divide by zero")
```

* Finally:

```python
finally:
    print("Cleanup")
```

* Custom exceptions:

```python
class MyError(Exception): pass
```

---

# 10. Popular Libraries

* **Web Development:**
  - `requests`: HTTP library for API calls
  - `flask`: Lightweight web framework
  - `django`: Full-featured web framework
  - `fastapi`: Modern API framework with async support

* **Data Science & Analysis:**
  - `numpy`: Numerical computing with arrays
  - `pandas`: Data manipulation and analysis
  - `matplotlib`: Plotting and visualization
  - `seaborn`: Statistical data visualization

* **Machine Learning:**
  - `scikit-learn`: Classic ML algorithms
  - `tensorflow`: Deep learning framework
  - `pytorch`: Deep learning with dynamic graphs
  - `xgboost`: Gradient boosting

* **Testing & Quality:**
  - `pytest`: Modern testing framework
  - `unittest`: Standard library testing
  - `coverage`: Code coverage measurement
  - `black`: Code formatter

* **Automation & Utilities:**
  - `selenium`: Web browser automation
  - `pyautogui`: GUI automation
  - `schedule`: Job scheduling
  - `click`: Command-line interfaces

**Library Examples:**

```python
# requests - HTTP API calls
import requests
response = requests.get('https://api.github.com/user', auth=('user', 'pass'))
print(response.status_code)
print(response.json())

# pandas - Data manipulation
import pandas as pd
df = pd.read_csv('data.csv')
print(df.head())
print(df.describe())

# numpy - Numerical operations
import numpy as np
arr = np.array([1, 2, 3, 4, 5])
print(arr.mean())  # 3.0
print(arr.reshape(5, 1))

# matplotlib - Basic plotting
import matplotlib.pyplot as plt
x = [1, 2, 3, 4, 5]
y = [1, 4, 9, 16, 25]
plt.plot(x, y)
plt.xlabel('X values')
plt.ylabel('Y values')
plt.title('Simple Plot')
plt.show()

# pytest - Testing example
def add(a, b):
    return a + b

def test_add():
    assert add(1, 2) == 3
    assert add(-1, 1) == 0
    assert add(0, 0) == 0
```

---

# 11. Testing & Debugging

* **pytest - Modern testing framework:**

```python
# test_math.py
import pytest

def add(a, b):
    return a + b

def test_add_positive():
    assert add(1, 2) == 3

def test_add_negative():
    assert add(-1, -2) == -3

def test_add_zero():
    assert add(0, 0) == 0

@pytest.mark.parametrize("a,b,expected", [
    (1, 2, 3),
    (-1, 1, 0),
    (0, 0, 0),
])
def test_add_parametrized(a, b, expected):
    assert add(a, b) == expected

# Fixtures
@pytest.fixture
def sample_data():
    return [1, 2, 3, 4, 5]

def test_sum(sample_data):
    assert sum(sample_data) == 15

# Mocking
from unittest.mock import Mock, patch

def test_api_call():
    with patch('requests.get') as mock_get:
        mock_get.return_value.status_code = 200
        mock_get.return_value.json.return_value = {'data': 'test'}

        # Your code that makes API call
        # response = requests.get('https://api.example.com')
        # assert response.status_code == 200
```

* **unittest - Standard library testing:**

```python
import unittest

class TestCalculator(unittest.TestCase):
    def setUp(self):
        self.calc = Calculator()

    def test_addition(self):
        self.assertEqual(self.calc.add(1, 2), 3)
        self.assertEqual(self.calc.add(-1, 1), 0)

    def test_division_by_zero(self):
        with self.assertRaises(ZeroDivisionError):
            self.calc.divide(10, 0)

    @classmethod
    def setUpClass(cls):
        print("Set up class")

    @classmethod
    def tearDownClass(cls):
        print("Tear down class")
```

* **Debugging techniques:**

```python
import pdb
import logging

# PDB debugger
def problematic_function(x):
    y = x * 2
    pdb.set_trace()  # Breakpoint
    z = y + 10
    return z

# Logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    filename='app.log'
)

logger = logging.getLogger(__name__)

def my_function():
    logger.debug("Starting function")
    try:
        # Some code
        logger.info("Operation successful")
    except Exception as e:
        logger.error(f"Error occurred: {e}")
        raise
```

* **Performance profiling:**

```python
import time
import cProfile

# Simple timing
start = time.time()
# Your code here
end = time.time()
print(f"Execution time: {end - start:.4f} seconds")

# Profiling
def slow_function():
    return sum(i**2 for i in range(10000))

cProfile.run('slow_function()')
```

---

# 12. Virtual Environments & Package Management

* Create virtualenv:

```bash
python3 -m venv env
source env/bin/activate  # Linux/Mac
env\Scripts\activate     # Windows
```

* Deactivate:

```bash
deactivate
```

* List installed packages:

```bash
pip list
```

* Freeze requirements:

```bash
pip freeze > requirements.txt
```

---

# 13. Best Practices & Tips

* **Code Style & PEP 8:**
  - Use 4 spaces for indentation
  - Limit lines to 79 characters
  - Use descriptive variable names
  - Add docstrings to functions and classes
  - Use `black` or `autopep8` for formatting

* **Performance Tips:**
  - Use list comprehensions over loops when possible
  - Prefer `collections.deque` for frequent appends/pops from both ends
  - Use `set` for membership testing
  - Avoid global variables
  - Use generators for large data processing

* **Security Best Practices:**
  - Never store sensitive data in code
  - Use environment variables for secrets
  - Validate and sanitize user inputs
  - Use parameterized queries for databases
  - Keep dependencies updated

* **Common Patterns & Idioms:**

```python
# EAFP (Easier to Ask for Forgiveness than Permission)
try:
    value = my_dict['key']
except KeyError:
    value = default_value

# LBYL (Look Before You Leap)
if 'key' in my_dict:
    value = my_dict['key']
else:
    value = default_value

# Context managers
class DatabaseConnection:
    def __enter__(self):
        self.connection = connect_to_db()
        return self.connection

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.connection.close()

with DatabaseConnection() as conn:
    # Use connection
    pass

# Generator functions
def fibonacci(n):
    a, b = 0, 1
    for _ in range(n):
        yield a
        a, b = b, a + b

for num in fibonacci(10):
    print(num)

# Memoization decorator
from functools import lru_cache

@lru_cache(maxsize=None)
def fibonacci_memo(n):
    if n < 2:
        return n
    return fibonacci_memo(n-1) + fibonacci_memo(n-2)
```

* **Async Programming (Python 3.7+):**

```python
import asyncio
import aiohttp

async def fetch_url(url):
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            return await response.text()

async def main():
    urls = ['https://example.com', 'https://google.com']
    tasks = [fetch_url(url) for url in urls]
    results = await asyncio.gather(*tasks)
    return results

# Run async function
asyncio.run(main())
```

* **Context Managers & Generators:**

```python
# Custom context manager
from contextlib import contextmanager

@contextmanager
def timer():
    start = time.time()
    try:
        yield
    finally:
        end = time.time()
        print(f"Elapsed: {end - start:.2f}s")

with timer():
    # Code to time
    time.sleep(1)

# Generator expressions
squares = (x**2 for x in range(1000000))  # Memory efficient
sum_of_squares = sum(squares)
```

---

# 14. Advanced Python Features

* **Metaclasses:**

```python
class SingletonMeta(type):
    _instances = {}

    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = super().__call__(*args, **kwargs)
        return cls._instances[cls]

class SingletonClass(metaclass=SingletonMeta):
    def __init__(self, value):
        self.value = value

# Usage
obj1 = SingletonClass(42)
obj2 = SingletonClass(24)
print(obj1 is obj2)  # True
```

* **Descriptors:**

```python
class LazyProperty:
    def __init__(self, func):
        self.func = func
        self.name = func.__name__

    def __get__(self, instance, owner):
        if instance is None:
            return self
        value = self.func(instance)
        setattr(instance, self.name, value)
        return value

class MyClass:
    @LazyProperty
    def expensive_property(self):
        print("Computing expensive property...")
        return sum(range(1000000))

obj = MyClass()
print(obj.expensive_property)  # Computed once
print(obj.expensive_property)  # Cached
```

* **Context Managers (Advanced):**

```python
from contextlib import contextmanager, ExitStack

@contextmanager
def nested_contexts(*managers):
    with ExitStack() as stack:
        yield [stack.enter_context(mgr) for mgr in managers]

# Usage
with nested_contexts(open('file1.txt'), open('file2.txt')) as files:
    # Work with multiple files
    pass
```

* **Introspection and Reflection:**

```python
import inspect

class MyClass:
    def method(self, arg1, arg2=None):
        return arg1 + (arg2 or 0)

# Get class info
print(inspect.getmembers(MyClass, predicate=inspect.isfunction))
print(inspect.signature(MyClass.method))

# Dynamic attribute access
obj = MyClass()
setattr(obj, 'dynamic_attr', 'value')
print(getattr(obj, 'dynamic_attr'))

# Check if attribute exists
print(hasattr(obj, 'method'))
```

* **Regular Expressions:**

```python
import re

# Basic patterns
pattern = r'\b\d{3}-\d{2}-\d{4}\b'  # SSN pattern
text = "My SSN is 123-45-6789"
match = re.search(pattern, text)
if match:
    print(f"Found SSN: {match.group()}")

# Groups and named groups
email_pattern = r'(?P<username>\w+)@(?P<domain>\w+\.\w+)'
match = re.match(email_pattern, 'user@example.com')
if match:
    print(match.group('username'))  # user
    print(match.group('domain'))    # example.com

# Substitution
text = "The quick brown fox"
result = re.sub(r'\b\w{4}\b', '****', text)  # Replace 4-letter words
print(result)  # The **** brown ****
```

* **Itertools and Functools:**

```python
from itertools import combinations, permutations, chain, islice
from functools import partial, reduce

# Combinations and permutations
items = [1, 2, 3]
print(list(combinations(items, 2)))   # [(1,2), (1,3), (2,3)]
print(list(permutations(items, 2)))  # [(1,2), (1,3), (2,1), (2,3), (3,1), (3,2)]

# Chain iterators
for item in chain([1, 2], [3, 4], [5]):
    print(item)  # 1 2 3 4 5

# Partial functions
def multiply(x, y):
    return x * y

double = partial(multiply, 2)
print(double(5))  # 10

# Reduce
numbers = [1, 2, 3, 4, 5]
product = reduce(lambda x, y: x * y, numbers)
print(product)  # 120
```

---

# 15. Common Pitfalls and Gotchas

* **Mutable Default Arguments:**

```python
def bad_append(item, mylist=[]):  # Wrong!
    mylist.append(item)
    return mylist

print(bad_append(1))  # [1]
print(bad_append(2))  # [1, 2] - Unexpected!

def good_append(item, mylist=None):  # Correct
    if mylist is None:
        mylist = []
    mylist.append(item)
    return mylist
```

* **Late Binding in Closures:**

```python
def create_multipliers():
    return [lambda x: i * x for i in range(4)]

multipliers = create_multipliers()
print([m(2) for m in multipliers])  # [6, 6, 6, 6] - Wrong!

# Fix with default argument
def create_multipliers_fixed():
    return [lambda x, i=i: i * x for i in range(4)]

multipliers_fixed = create_multipliers_fixed()
print([m(2) for m in multipliers_fixed])  # [0, 2, 4, 6]
```

* **Integer Division in Python 2 vs 3:**

```python
# Python 2: 5/2 = 2
# Python 3: 5/2 = 2.5

# Always use float division
result = 5 / 2.0  # or from __future__ import division
```

* **Copying Lists:**

```python
original = [1, [2, 3]]
shallow_copy = original[:]  # or list(original)
shallow_copy[1].append(4)
print(original)  # [1, [2, 3, 4]] - Modified!

import copy
deep_copy = copy.deepcopy(original)
deep_copy[1].append(5)
print(original)  # [1, [2, 3, 4]] - Unchanged
```

* **String Concatenation in Loops:**

```python
# Inefficient
result = ""
for i in range(1000):
    result += str(i)

# Efficient
result = "".join(str(i) for i in range(1000))
```

---

# Quick Reference: Common One-liners

```python
# Swap variables
a, b = b, a

# Reverse list
rev = mylist[::-1]

# Check if all elements are True
all_true = all(mylist)

# Flatten nested list
flat = [item for sublist in nested_list for item in sublist]

# Remove duplicates while preserving order
unique = list(dict.fromkeys(mylist))

# Find most common element
from collections import Counter
most_common = Counter(mylist).most_common(1)[0][0]

# Group by key
from itertools import groupby
groups = {k: list(g) for k, g in groupby(sorted(data, key=key_func), key_func)}

# Ternary operator
result = x if condition else y

# Dictionary get with default
value = my_dict.get('key', 'default')

# List slicing with step
every_other = mylist[::2]

# Read CSV using pandas
import pandas as pd
df = pd.read_csv('file.csv')
```

---

*End of cheat sheet — master Python from basics to expert-level practices!*
