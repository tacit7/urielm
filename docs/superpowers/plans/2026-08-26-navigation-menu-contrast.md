# Navigation menu contrast implementation plan

1. Add a failing source contract requiring `bg-base-200` on both dropdown panels.
2. Update only the two dropdown surface classes.
3. Run focused tests, asset build, UI detector, strict compile check, and `mix precommit`.
4. Commit task-owned files and complete EITS task 9259.
