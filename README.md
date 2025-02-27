# SeismoTracker

SeismoTracker is a Docker-based multi-service application designed to track and analyze seismic activity and earthquake data. The project comprises several services for database management, data fetching, data initialization, and visualization/dashboard operations.

## Contents

- **seismotracker-init**: Responsible for preparing initial data by importing external datasets (e.g., Geonames).
- **seismotracker-fetcher**: Fetches seismic data from external sources and processes it into the database.
- **seismotracker-lightdash**: Provides a Lightdash-based visualization interface for data analysis and reporting.
- **seismotracker-postgres**: Hosts the PostgreSQL database that stores application data. Initial setup and data seeding are performed using an initialization SQL file.
- **seismotracker-headless-browser**: Offers headless Chromium-based automation for services like Lightdash.

## Project Structure

```
.
├── .gitmodules             # Submodule definitions
├── docker-compose.yml       # Docker Compose configuration for all services
├── fetch_submodule.sh       # Script for fetching/updating submodules
├── init/                   # Dockerfile and related files for seismotracker-init service
├── postgres/               # Dockerfile and configurations for seismotracker-postgres service
├── seismotracker/          # Source code and Dockerfile for seismotracker-fetcher service
├── lightdash/              # Configuration and Dockerfile for seismotracker-lightdash service
└── (other directories)     # Additional helper files (e.g., github, astro)
```

## Requirements

- [Docker](https://www.docker.com/get-started) (latest version recommended)
- [Docker Compose](https://docs.docker.com/compose/install/) (version 2 recommended)
- Ensure you update submodules by running the `fetch_submodule.sh` script before starting the project.

## Installation and Running

1. **Clone the Repository**

   ```bash
   git clone https://github.com/your_username/seismotracker.git
   cd seismotracker
   ```

2. **Update Submodules**

   If submodules are used, update them with:

   ```bash
   ./fetch_submodule.sh
   ```

3. **Start Docker Services**

   Launch all services in detached mode:

   ```bash
   docker-compose up -d
   ```

4. **Check Service Status**

   Verify the status of the Docker containers:

   ```bash
   docker-compose ps
   ```

## Configuration

### Environment Variables

- **seismotracker-fetcher**:
  - `POSTGRES_URI`: PostgreSQL connection string (e.g., `postgres://postgres:password@seismotracker-postgres:5432/seismotracker?sslmode=disable`)

- **seismotracker-lightdash**: Contains various environment variables for Lightdash and database connectivity. Adjust these in the `docker-compose.yml` file as needed.

- **seismotracker-postgres**: Basic PostgreSQL configurations (username, password, database name) are defined here.

### Volumes and Connections

- **Data Volumes**:
  - Geonames data is mounted at `/project/seismotracker/data/geonames` for the `seismotracker-init` service.
  - PostgreSQL data is stored in `/project/seismotracker/data/postgres`.
  - Lightdash-related data and configuration files are mounted at `/project/seismotracker/lightdash`.

- **Network Configuration**: All services communicate over a dedicated Docker network named `seismotracker-network`.

## Access Points

- **Lightdash Interface**: [http://localhost:8081](http://localhost:8081)
- **Headless Browser**: [http://localhost:3001](http://localhost:3001)
- **PostgreSQL**: Accessible on port `5432` on the local machine.

## Updates and Maintenance

- Project updates are managed via Git submodules and the `fetch_submodule.sh` script.
- Some containers are labeled for automatic updates with Watchtower to ensure services remain current.

## Troubleshooting

- **Connection Issues**: Due to service dependencies, connection errors (e.g., between the database and Lightdash) may occur. Check the logs for the relevant service:

  ```bash
  docker-compose logs seismotracker-postgres
  ```

- **Service Health**: If a service appears "unhealthy," review its health check configuration and logs to diagnose the issue.

## Contributing

If you wish to contribute or enhance the project, please submit a pull request or open an issue with your suggestions.

## License

For license details, please refer to the [LICENSE](LICENSE) file.

---

This README.md provides an overview of the core components and operational steps of the project. Adjust the environment variables and configurations as needed to suit your specific setup.