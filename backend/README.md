# backend

rails 8.1 api. handles spotify oauth, elo-based song ranking, and matchup selection.

## stack

- ruby on rails 8.1 (api mode)
- postgresql
- spotify oauth via omniauth
- jwt for auth tokens

## setup

```bash
bundle install
cp .env.example .env  # fill in credentials
bin/rails db:create db:migrate
```

## env vars

| var                     | description                                                             |
| ----------------------- | ----------------------------------------------------------------------- |
| `DATABASE_URL`          | postgres connection string                                              |
| `SPOTIFY_CLIENT_ID`     | spotify app client id                                                   |
| `SPOTIFY_CLIENT_SECRET` | spotify app client secret                                               |
| `SPOTIFY_REDIRECT_URI`  | oauth callback url (e.g. `http://127.0.0.1:3000/auth/spotify/callback`) |
| `JWT_SECRET`            | secret for signing jwts                                                 |
| `FRONTEND_ORIGIN`       | cors allowed origin (e.g. `http://localhost:5173`)                      |
| `RAILS_MASTER_KEY`      | rails credentials master key (production)                               |

## commands

```bash
bin/rails server          # start dev server on :3000
bin/rails db:migrate      # run migrations
bin/rails db:reset        # drop, create, migrate
bin/rails console         # rails console
bundle exec rubocop       # lint
bundle exec brakeman      # security scan
```

## api

```
GET    /api/v1/auth/me
DELETE /api/v1/auth/logout

GET    /api/v1/rankings
POST   /api/v1/rankings
PATCH  /api/v1/rankings/:id
DELETE /api/v1/rankings/:id
POST   /api/v1/rankings/:id/reset

GET    /api/v1/rankings/:id/songs
POST   /api/v1/rankings/:id/songs
DELETE /api/v1/rankings/:id/songs/:song_id

GET    /api/v1/rankings/:id/matchups/next
POST   /api/v1/rankings/:id/matchups

GET    /api/v1/rankings/:id/export

GET    /api/v1/spotify/search/artists
GET    /api/v1/spotify/search/albums
GET    /api/v1/spotify/search/tracks
GET    /api/v1/spotify/artists/:id/albums
GET    /api/v1/spotify/artists/:id/tracks
GET    /api/v1/spotify/albums/:id/tracks
```
