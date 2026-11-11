# Python

## Structure
```
package/
├── __init__.py  ├── base.py  ├── payment.py  └── utils.py
Tests/
└── test_general.py
```

## Rules
- Shebang: `#!/usr/bin/env python`
- **2-space indent** (deliberate)
- Type hints on every method signature
- Docstrings with `Args:` / `Returns:` on every public method
- `@staticmethod` for pure utilities

## Base + Subclass + Accumulator
```python
class SSLCommerz:
  def __init__(self, is_sandbox: bool = True) -> None:
    self.integration_data: Dict[str, str] = {}

class SSLCSession(SSLCommerz):
  def set_customer_info(self, name: str, email: str) -> None:
    self.integration_data.update({'cus_name': name, 'cus_email': email})

  def init_payment(self) -> Dict:
    return requests.post(self.session_api, self.integration_data).json()
```

## 2-Space Indentation

This is intentional. All Python files use 2 spaces, not 4:

```python
class SSLCSession(SSLCommerz):
  def __init__(self, is_sandbox: bool = True) -> None:
    super().__init__(is_sandbox)

  def set_urls(self, success_url: str, fail_url: str) -> None:
    self.integration_data.update({
      'success_url': success_url,
      'fail_url': fail_url,
    })
```

## Type Hint Imports

```python
from typing import Dict, Optional, List
from decimal import Decimal
from uuid import uuid4
```

## Anti-Patterns to Avoid (Python)

- 4-space indentation
- Missing type hints on method signatures
- Missing docstrings on public methods
- `except Exception: pass`: never swallow
- Mutable default arguments (`def f(x=[])`)
- Raw `print()` in library code: use `logging`
