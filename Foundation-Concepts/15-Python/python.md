# Python Cheat Sheet (Beginner → Expert)

> Covers Python basics, data types, control flow, functions, OOP, modules, file I/O, exceptions, libraries, testing, and best practices.

---

## Table of Contents

1. Introduction & Setup
2. Data Types & Variables
3. Operators & Expressions
4. Control Flow
5. Functions
6. Classes & OOP
7. Modules & Packages
8. File I/O
9. Exceptions & Error Handling
10. Popular Libraries
11. Testing & Debugging
12. Virtual Environments & Package Management
13. Best Practices & Tips

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
* Type checking:

```python
a = 5
print(type(a))  # <class 'int'>
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
else:
    print("Non-positive")
```

* Loops:

```python
for i in range(5): print(i)
while x < 10: x += 1
```

* Comprehensions:

```python
squares = [x**2 for x in range(10) if x%2==0]
```

---

# 5. Functions

* Define function:

```python
def add(a, b):
    return a + b
```

* Default & keyword args:

```python
def greet(name="User"):
    print(f"Hello {name}")
```

* Lambda:

```python
square = lambda x: x**2
```

* Decorators:

```python
def decorator(fn):
    def wrapper():
        print("Before")
        fn()
    return wrapper
```

---

# 6. Classes & OOP

* Define class:

```python
class Person:
    def __init__(self, name, age):
        self.name = name
        self.age = age
    def greet(self):
        print(f"Hello {self.name}")
```

* Inheritance:

```python
class Employee(Person):
    def __init__(self, name, age, emp_id):
        super().__init__(name, age)
        self.emp_id = emp_id
```

* Encapsulation: `_private_var`
* Polymorphism: method overriding

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

* Web: `requests`, `flask`, `django`
* Data: `numpy`, `pandas`, `matplotlib`, `seaborn`
* ML: `scikit-learn`, `tensorflow`, `pytorch`
* Testing: `pytest`, `unittest`
* Automation: `selenium`, `pyautogui`

---

# 11. Testing & Debugging

* Unit testing:

```python
import unittest
class TestMath(unittest.TestCase):
    def test_add(self):
        self.assertEqual(1+1, 2)
```

* Debugging:

```python
import pdb; pdb.set_trace()
```

* Logging:

```python
import logging
logging.basicConfig(level=logging.INFO)
logging.info("message")
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

# Quick Reference: Common One-liners

```python
# Swap variables
a, b = b, a

# Reverse list
rev = mylist[::-1]

# Check if all elements are True
all_true = all(mylist)

# Read CSV using pandas
import pandas as pd
df = pd.read_csv('file.csv')
```

---

*End of cheat sheet — master Python from basics to expert-level practices!*
