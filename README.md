<div align="center">
    <h1>music-ranker</h1>
</div>

---

rank your songs head-to-head. pick between two tracks, elo scores update, repeat until your taste is law.

built with spotify — search and import artists, albums, or tracks into any ranking you create.

## structure

| directory                         | description                                  |
| --------------------------------- | -------------------------------------------- |
| [`backend/`](backend/README.md)   | rails 8.1 api — auth, elo, matchup selection |
| [`frontend/`](frontend/README.md) | sveltekit 5 app — ui                         |
