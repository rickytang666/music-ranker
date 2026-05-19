<div align="center">
    <h1>music-ranker</h1>
</div>

---

rank your songs head-to-head. pick between two tracks, elo scores update, repeat until your taste is law.

built with spotify — search and import artists, albums, or tracks into any ranking you create.

## features

- **head-to-head matchups** — pick between two songs; elo scores update based on upset magnitude
- **smart selection** — prefers fresh pairs (pair freshness weight) and nearby elo scores (proximity weight)
- **flagging** — mark songs as underrated, overrated, or unsure; instantly queues up 5 targeted challenges
- **album rankings** — view albums sorted by mean elo, with average rank per album
- **spotify import** — search or browse artists to add albums and tracks
- **export** — share your ranking as a ranked list

## structure

| directory                         | description                                  |
| --------------------------------- | -------------------------------------------- |
| [`backend/`](backend/README.md)   | rails 8.1 api — auth, elo, matchup selection |
| [`frontend/`](frontend/README.md) | sveltekit 5 app — ui                         |
