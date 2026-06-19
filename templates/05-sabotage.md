SABOTAGE_TARGET:
- Core function under test

PROCEDURE:
1. cp {source} {source}.bak
2. Changed {func} to return {broken_value}
3. Run tests: {command}
   - Result: {PASS/FAIL}  (expected: FAIL)
4. cp {source}.bak {source} && rm {source}.bak
5. Regression: {command}
   - Result: {PASS/FAIL}  (expected: PASS)

VERDICT:
- Sabotage caught: {YES/NO}
- Tests are real: {YES/NO}
