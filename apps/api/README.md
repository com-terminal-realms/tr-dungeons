# Terminal Realms: Dungeons - Backend API

Python/FastAPI backend for Terminal Realms: Dungeons game server.

## Features

- **AWS Lambda Functions**: Serverless game server logic
- **GraphQL API**: AppSync-powered real-time game state
- **PostgreSQL**: MajorMUD data storage and querying
- **Generated Models**: orb-schema-generator Python models

## Structure

```
apps/api/
├── models/              # Generated Pydantic models (orb-schema-generator)
├── enums/               # Generated enums
├── graphql/             # Generated GraphQL schemas
├── lambda_functions/    # AWS Lambda handlers
│   ├── game_state/     # Game state management
│   ├── player_actions/ # Player action handlers
│   └── dungeon_gen/    # Dungeon generation
└── tests/              # API tests
```

## Development

```bash
# Install dependencies
pipenv install --dev

# Run tests
pipenv run pytest

# Generate models from schemas
pipenv run orb-schema generate --config ../../schema-generator.yml
```

## Deployment

Deployed via CDK stacks in `infrastructure/cdk/`.

See [infrastructure README](../../infrastructure/README.md) for deployment instructions.
